// morphed-ios/Morphed/Core/Auth/AuthManager.swift

import Foundation
import AuthenticationServices
import Combine
import Supabase
import CryptoKit
import UIKit

@MainActor
final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    
    static let shared = AuthManager()
    
    private var authStateTask: Task<Void, Never>?
    private var webAuthSession: ASWebAuthenticationSession?
    private let presentationContextProvider = AuthPresentationContextProvider()
    private var lastSyncedUserId: String?
    
    private init() {
        syncFromCurrentUser()
        listenForAuthChanges()
    }
    
    deinit {
        authStateTask?.cancel()
    }
    
    func checkAuthentication() {
        syncFromCurrentUser()
    }
    
    func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        _ = try await supabase.auth.signIn(email: email, password: password)
        try await refreshSessionAndValidateProfile()
    }

    func login(identifier: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        if trimmed.contains("@") {
            _ = try await supabase.auth.signIn(email: trimmed, password: password)
        } else {
            _ = try await supabase.auth.signIn(phone: trimmed, password: password)
        }
        
        try await refreshSessionAndValidateProfile()
    }
    
    func signUp(email: String, password: String, name: String) async throws -> Bool {
        try await signUp(identifier: email, password: password, name: name)
    }

    func signUp(identifier: String, password: String, name: String) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !password.isEmpty, !name.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        let metadata: [String: AnyJSON] = ["name": .string(name)]
        if trimmed.contains("@") {
            _ = try await supabase.auth.signUp(email: trimmed, password: password, data: metadata)
        } else {
            _ = try await supabase.auth.signUp(phone: trimmed, password: password, data: metadata)
        }
        let session = try? await supabase.auth.session
        updateFromSession(session)
        if let user = session?.user ?? supabase.auth.currentUser {
            await createOrUpdateProfile(for: user, nameOverride: name)
        }
        return session == nil
    }
    
    func signInWithOAuth(provider: Provider) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let url = try await supabase.auth.getOAuthSignInURL(
            provider: provider,
            redirectTo: SupabaseConfig.redirectURL
        )
        
        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: SupabaseConfig.redirectScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL else {
                    continuation.resume(throwing: AuthError.oauthFailed)
                    return
                }
                
                continuation.resume(returning: callbackURL)
            }
            
            session.presentationContextProvider = presentationContextProvider
            session.prefersEphemeralWebBrowserSession = true
            webAuthSession = session
            session.start()
        }
        
        webAuthSession = nil
        _ = try await supabase.auth.session(from: callbackURL)
        try await refreshSessionAndValidateProfile()
    }
    
    func logout() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
        } catch {
            // Silently handle sign out errors
        }
        updateFromSession(nil)
    }

    func deleteAccount() async throws {
        isLoading = true
        defer { isLoading = false }

        let session = try await supabase.auth.session
        let url = SupabaseConfig.url.appendingPathComponent("functions/v1/delete-account")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["access_token": session.accessToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? ""
            let message = "Delete failed (\(httpResponse.statusCode)). \(body)"
            throw NSError(domain: "DeleteAccount", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: message.trimmingCharacters(in: .whitespacesAndNewlines)
            ])
        }

        do {
            try await supabase.auth.signOut()
        } catch {
            // Best-effort sign out after deletion.
        }

        updateFromSession(nil)
    }

    func deleteHistory() async throws {
        isLoading = true
        defer { isLoading = false }

        let user = try await requireAuthenticatedUser()
        let localPairIds = Set(loadHistoryItems().map { $0.pairId.isEmpty ? $0.id : $0.pairId })

        let response: PostgrestResponse<[CreatedImageRow]> = try await supabase
            .from("created_images")
            .select("id, original_path, created_path")
            .eq("profile_id", value: user.id.uuidString)
            .execute()

        let remotePairIds = Set(response.value.map { $0.id })
        let storagePairIds = localPairIds.union(remotePairIds)
        let pathsFromRows = response.value.flatMap { [$0.originalPath, $0.createdPath] }
        let pathsFromPairs = storagePairIds.flatMap { pairId in
            ["\(user.id.uuidString)/\(pairId)/original.jpg", "\(user.id.uuidString)/\(pairId)/created.jpg"]
        }
        let paths = Array(Set(pathsFromRows + pathsFromPairs))
        if !paths.isEmpty {
            _ = try await supabase.storage
                .from("morphed-images")
                .remove(paths: paths)
        }

        _ = try await supabase
            .from("created_images")
            .delete()
            .eq("profile_id", value: user.id.uuidString)
            .execute()

        UserDefaults.standard.removeObject(forKey: "morphed_history")
    }

    func deleteHistoryItems(pairIds: [String]) async throws {
        guard !pairIds.isEmpty else { return }
        let user = try await requireAuthenticatedUser()

        let storagePaths = pairIds.flatMap { pairId in
            ["\(user.id.uuidString)/\(pairId)/original.jpg", "\(user.id.uuidString)/\(pairId)/created.jpg"]
        }
        _ = try await supabase.storage
            .from("morphed-images")
            .remove(paths: storagePaths)

        for pairId in pairIds {
            _ = try await supabase
                .from("created_images")
                .delete()
                .eq("profile_id", value: user.id.uuidString)
                .eq("id", value: pairId)
                .execute()
        }
    }
    
    private func listenForAuthChanges() {
        authStateTask?.cancel()
        authStateTask = Task { @MainActor [weak self] in
            for await (_, session) in supabase.auth.authStateChanges {
                self?.updateFromSession(session)
            }
        }
    }
    
    private func syncFromCurrentUser() {
        if let user = supabase.auth.currentUser {
            currentUser = AppUser(from: user)
            isAuthenticated = true
            let userId = user.id.uuidString
            if lastSyncedUserId != userId {
                lastSyncedUserId = userId
                Task { [weak self] in
                    await self?.syncLocalHistory(for: userId)
                }
            }
            Task { [weak self] in
                await self?.refreshProfileDetails(for: user)
            }
        }
    }
    
    private func refreshSession() async {
        let session = try? await supabase.auth.session
        updateFromSession(session)
    }

    private func refreshSessionAndValidateProfile() async throws {
        let session = try? await supabase.auth.session
        updateFromSession(session)
        guard let user = session?.user ?? supabase.auth.currentUser else {
            throw AuthError.invalidCredentials
        }
        let exists = await profileExists(for: user)
        if !exists {
            try? await supabase.auth.signOut()
            updateFromSession(nil)
            throw AuthError.profileMissing
        }
        await refreshProfileDetails(for: user)
    }
    
    private func updateFromSession(_ session: Session?) {
        if let user = session?.user ?? supabase.auth.currentUser {
            let baseUser = AppUser(from: user)
            let isSameUser = currentUser?.id == baseUser.id
            let existingAvatar = isSameUser ? currentUser?.avatarURL : nil
            let existingName = isSameUser ? currentUser?.name : nil

            // If the authenticated user has changed, reset any device-local,
            // non-account-scoped state so it doesn't leak across accounts.
            if !isSameUser {
                // Clear local history for privacy so a new account on the same
                // device never sees another account's images.
                UserDefaults.standard.removeObject(forKey: "morphed_history")

                // Reset local subscription state so free/pro/premium status
                // never "sticks" from a previous account.
                SubscriptionManager.shared.resetToFree()
            }

            currentUser = AppUser(
                id: baseUser.id,
                email: baseUser.email,
                name: existingName ?? baseUser.name,
                avatarURL: existingAvatar
            )
            isAuthenticated = true

            let userId = user.id.uuidString
            if lastSyncedUserId != userId {
                lastSyncedUserId = userId
                Task { [weak self] in
                    await self?.syncLocalHistory(for: userId)
                }
            }
        } else {
            // Logged out: clear local, device-scoped state so the next login
            // starts clean.
            currentUser = nil
            isAuthenticated = false
            lastSyncedUserId = nil
            UserDefaults.standard.removeObject(forKey: "morphed_history")
            SubscriptionManager.shared.resetToFree()
        }
    }

    private func createOrUpdateProfile(for user: Supabase.User, nameOverride: String? = nil) async {
        let nameFromMetadata = user.userMetadata["name"]?.stringValue
        let fallbackName = user.email?.components(separatedBy: "@").first?.capitalized ?? "User"
        let resolvedName = nameOverride?.isEmpty == false ? nameOverride! : (nameFromMetadata ?? fallbackName)
        let payload = ProfilePayload(
            id: user.id.uuidString,
            email: user.email,
            phone: user.phone,
            name: resolvedName,
            avatarURL: nil
        )
        
        do {
            try await supabase.from("profiles")
                .upsert(payload, onConflict: "id")
                .execute()
        } catch {
            // Non-fatal: auth should still succeed even if profile upsert fails.
        }
    }
    
    private func profileExists(for user: Supabase.User) async -> Bool {
        do {
            let response: PostgrestResponse<ProfileCheck> = try await supabase
                .from("profiles")
                .select("id")
                .eq("id", value: user.id.uuidString)
                .single()
                .execute()
            return !response.value.id.isEmpty
        } catch {
            return false
        }
    }

    private func refreshProfileDetails(for user: Supabase.User) async {
        do {
            let response: PostgrestResponse<ProfileDetails> = try await supabase
                .from("profiles")
                .select("name, avatar_url")
                .eq("id", value: user.id.uuidString)
                .single()
                .execute()
            let resolvedName = response.value.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedAvatar = response.value.avatarURL?.trimmingCharacters(in: .whitespacesAndNewlines)
            updateCurrentUser(name: resolvedName.isEmpty ? nil : resolvedName,
                              avatarURL: resolvedAvatar?.isEmpty == false ? resolvedAvatar : nil,
                              fallbackEmail: user.email)
        } catch {
            // Non-fatal: keep local name if profile fetch fails.
        }
    }
    
    private func updateCurrentUser(name: String? = nil, avatarURL: String? = nil, fallbackEmail: String?) {
        let resolvedEmail = currentUser?.email ?? fallbackEmail ?? ""
        let resolvedId = currentUser?.id ?? supabase.auth.currentUser?.id.uuidString ?? ""
        guard !resolvedId.isEmpty else { return }
        let resolvedName = name ?? currentUser?.name ?? "User"
        let resolvedAvatar = avatarURL ?? currentUser?.avatarURL
        currentUser = AppUser(id: resolvedId, email: resolvedEmail, name: resolvedName, avatarURL: resolvedAvatar)
    }
    
    func updateProfileName(_ name: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw AuthError.invalidName
        }
        let user = try await requireAuthenticatedUser()
        
        _ = try await supabase.auth.update(
            user: UserAttributes(data: ["name": .string(trimmed)])
        )
        
        try await supabase
            .from("profiles")
            .update(["name": trimmed])
            .eq("id", value: user.id.uuidString)
            .execute()
        
        updateCurrentUser(name: trimmed, avatarURL: nil, fallbackEmail: user.email)
        await refreshProfileDetails(for: user)
    }
    
    func updateProfileAvatar(_ image: UIImage) async throws {
        let user = try await requireAuthenticatedUser()
        let resized = ImageUtils.resizeImage(image, maxDimension: 512) ?? image
        guard let data = ImageUtils.compressToJPEG(resized, quality: 0.85) else {
            throw AuthError.invalidImage
        }
        
        let path = "\(user.id.uuidString)/avatar.jpg"
        let options = FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)
        _ = try await supabase.storage
            .from("avatars")
            .upload(path, data: data, options: options)
        
        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)
        
        try await supabase
            .from("profiles")
            .update(["avatar_url": publicURL.absoluteString])
            .eq("id", value: user.id.uuidString)
            .execute()
        
        updateCurrentUser(name: nil, avatarURL: publicURL.absoluteString, fallbackEmail: user.email)
        await refreshProfileDetails(for: user)
    }

    func storeCreatedImagePair(
        original: UIImage,
        created: UIImage,
        mode: String,
        pairId: String? = nil
    ) async throws -> String {
        let session = try await supabase.auth.session
        let userId = session.user.id.uuidString

        let resizedOriginal = ImageUtils.resizeImage(original, maxDimension: 2048) ?? original
        let resizedCreated = ImageUtils.resizeImage(created, maxDimension: 2048) ?? created

        guard let originalData = ImageUtils.compressToJPEG(resizedOriginal, quality: 0.9),
              let createdData = ImageUtils.compressToJPEG(resizedCreated, quality: 0.9) else {
            throw AuthError.invalidImage
        }

        let originalHash = sha256Hex(originalData)
        let existingPairId = try await resolveOriginalPair(
            hash: originalHash,
            mode: mode,
            accessToken: session.accessToken
        )
        let deterministicPairId = deterministicPairId(originalHash: originalHash, mode: mode)
        let finalPairId = existingPairId ?? deterministicPairId

        if let existingPairId {
            return existingPairId
        }

        if try await createdImageExists(pairId: deterministicPairId, userId: userId) {
            return deterministicPairId
        }
        let finalBasePath = "\(userId)/\(finalPairId)"
        let finalOriginalPath = "\(finalBasePath)/original.jpg"
        let finalCreatedPath = "\(finalBasePath)/created.jpg"

        let options = FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)

        if existingPairId == nil {
            _ = try await supabase.storage
                .from("morphed-images")
                .upload(finalOriginalPath, data: originalData, options: options)
        }

        _ = try await supabase.storage
            .from("morphed-images")
            .upload(finalCreatedPath, data: createdData, options: options)

        let payload = CreatedImagePayload(
            id: finalPairId,
            profileId: userId,
            originalPath: finalOriginalPath,
            createdPath: finalCreatedPath,
            mode: mode,
            originalHash: originalHash
        )

        _ = try await supabase
            .from("created_images")
            .upsert(payload, onConflict: "id")
            .execute()

        return finalPairId
    }

    private func createdImageExists(pairId: String, userId: String) async throws -> Bool {
        let response: PostgrestResponse<[CreatedImageIdRow]> = try await supabase
            .from("created_images")
            .select("id")
            .eq("profile_id", value: userId)
            .eq("id", value: pairId)
            .limit(1)
            .execute()
        return !response.value.isEmpty
    }

    private func resolveOriginalPair(hash: String, mode: String, accessToken: String) async throws -> String? {
        let url = SupabaseConfig.url.appendingPathComponent("functions/v1/resolve-original")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["original_hash": hash, "mode": mode])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return nil }
        if !(200...299).contains(httpResponse.statusCode) {
            return nil
        }
        let decoded = try? JSONDecoder().decode(OriginalResolveResponse.self, from: data)
        return decoded?.pairId
    }

    private func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func deterministicPairId(originalHash: String, mode: String) -> String {
        let combined = "\(originalHash)|\(mode)"
        let digest = SHA256.hash(data: Data(combined.utf8))
        var bytes = Array(digest)
        bytes[6] = (bytes[6] & 0x0F) | 0x50 // version 5
        bytes[8] = (bytes[8] & 0x3F) | 0x80 // RFC 4122 variant
        let hex = bytes.prefix(16).map { String(format: "%02x", $0) }.joined()
        let part1 = String(hex.prefix(8))
        let part2 = String(hex.dropFirst(8).prefix(4))
        let part3 = String(hex.dropFirst(12).prefix(4))
        let part4 = String(hex.dropFirst(16).prefix(4))
        let part5 = String(hex.dropFirst(20).prefix(12))
        return "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
    }

    private func syncLocalHistory(for userId: String) async {
        var items = loadHistoryItems()
        guard !items.isEmpty else { return }
        var didUpdate = false

        for index in items.indices {
            if items[index].isSynced {
                continue
            }

            guard let originalImage = items[index].originalImage,
                  let editedImage = items[index].editedImage else {
                continue
            }

            do {
                let finalPairId = try await storeCreatedImagePair(
                    original: originalImage,
                    created: editedImage,
                    mode: items[index].mode.rawValue,
                    pairId: items[index].pairId.isEmpty ? items[index].id : items[index].pairId
                )
                items[index].pairId = finalPairId
                items[index].isSynced = true
                didUpdate = true
            } catch {
                continue
            }
        }

        if didUpdate {
            saveHistoryItems(items)
        }
    }

    private func loadHistoryItems() -> [HistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: "morphed_history"),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return []
        }
        return decoded
    }

    private func saveHistoryItems(_ items: [HistoryItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "morphed_history")
        }
    }
    
    func updatePassword(oldPassword: String, newPassword: String) async throws {
        let trimmedOld = oldPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNew = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOld.isEmpty else {
            throw AuthError.invalidCredentials
        }
        guard trimmedNew.count >= 8 else {
            throw AuthError.invalidPassword
        }
        
        let user = try await requireAuthenticatedUser()
        if let email = user.email, !email.isEmpty {
            _ = try await supabase.auth.signIn(email: email, password: trimmedOld)
        } else if let phone = user.phone, !phone.isEmpty {
            _ = try await supabase.auth.signIn(phone: phone, password: trimmedOld)
        } else {
            throw AuthError.invalidCredentials
        }
        
        _ = try await supabase.auth.update(user: UserAttributes(password: trimmedNew))
    }
    
    func handleAuthCallback(url: URL) async {
        guard url.scheme == SupabaseConfig.redirectScheme else { return }
        do {
            _ = try await supabase.auth.session(from: url)
            try await refreshSessionAndValidateProfile()
        } catch {
            return
        }
    }

    private func requireAuthenticatedUser() async throws -> Supabase.User {
        do {
            let session = try await supabase.auth.session
            updateFromSession(session)
            return session.user
        } catch {
            if let user = supabase.auth.currentUser {
                return user
            }
            throw AuthError.invalidCredentials
        }
    }
}

private struct ProfileCheck: Decodable {
    let id: String
}

private struct ProfileDetails: Decodable {
    let name: String
    let avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case avatarURL = "avatar_url"
    }
}

private struct ProfilePayload: Encodable {
    let id: String
    let email: String?
    let phone: String?
    let name: String
    let avatarURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case name
        case avatarURL = "avatar_url"
    }
}

private struct CreatedImagePayload: Encodable {
    let id: String
    let profileId: String
    let originalPath: String
    let createdPath: String
    let mode: String
    let originalHash: String

    enum CodingKeys: String, CodingKey {
        case id
        case profileId = "profile_id"
        case originalPath = "original_path"
        case createdPath = "created_path"
        case mode
        case originalHash = "original_hash"
    }
}

private struct CreatedImageRow: Decodable {
    let id: String
    let originalPath: String
    let createdPath: String

    enum CodingKeys: String, CodingKey {
        case id
        case originalPath = "original_path"
        case createdPath = "created_path"
    }
}

private struct CreatedImageIdRow: Decodable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id
    }
}

private struct OriginalResolveResponse: Decodable {
    let exists: Bool
    let pairId: String?

    enum CodingKeys: String, CodingKey {
        case exists
        case pairId = "pair_id"
    }
}

struct AppUser: Codable {
    let id: String
    let email: String
    let name: String
    let avatarURL: String?
    
    init(from user: Supabase.User) {
        self.id = String(describing: user.id)
        self.email = user.email ?? ""
        if let metadataName = user.userMetadata["name"]?.stringValue, !metadataName.isEmpty {
            self.name = metadataName
        } else if let emailName = user.email?.components(separatedBy: "@").first, !emailName.isEmpty {
            self.name = emailName.capitalized
        } else {
            self.name = "User"
        }
        self.avatarURL = nil
    }
    
    init(id: String, email: String, name: String, avatarURL: String?) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarURL = avatarURL
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidName
    case invalidImage
    case invalidPassword
    case invalidPhone
    case invalidOTP
    case oauthFailed
    case profileMissing
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidName:
            return "Name can't be empty"
        case .invalidImage:
            return "Invalid image selected"
        case .invalidPassword:
            return "Password must be at least 8 characters"
        case .invalidPhone:
            return "Enter a valid phone number"
        case .invalidOTP:
            return "Enter the verification code"
        case .oauthFailed:
            return "OAuth failed. Please try again."
        case .profileMissing:
            return "Account not verified yet. Try again or sign up."
        case .networkError:
            return "Network error. Please try again."
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

final class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let window = scene?.windows.first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}

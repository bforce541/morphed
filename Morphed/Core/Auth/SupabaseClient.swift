// morphed-ios/Morphed/Core/Auth/SupabaseClient.swift

import Foundation
import Supabase

enum SupabaseConfig {
    static let url: URL = {
        let value = requireInfoPlistValue("SUPABASE_URL")
        guard let url = URL(string: value) else {
            fatalError("SUPABASE_URL is not a valid URL")
        }
        return url
    }()
    static let anonKey: String = requireInfoPlistValue("SUPABASE_ANON_KEY")
    static let redirectScheme: String = requireInfoPlistValue("SUPABASE_REDIRECT_SCHEME")
    static let redirectURL: URL = {
        guard let url = URL(string: "\(redirectScheme)://login-callback") else {
            fatalError("SUPABASE_REDIRECT_SCHEME is not a valid URL scheme")
        }
        return url
    }()
    
    private static func requireInfoPlistValue(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Missing \(key) in Info.plist")
        }
        return value
    }
}

let supabase = SupabaseClient(supabaseURL: SupabaseConfig.url, supabaseKey: SupabaseConfig.anonKey)

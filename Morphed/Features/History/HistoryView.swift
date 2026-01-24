// morphed-ios/Morphed/Features/History/HistoryView.swift

import SwiftUI
import Combine

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @StateObject private var router = AppRouter.shared
    @State private var selectedImage: HistoryItem?
    @State private var isSelecting = false
    @State private var selectedIds = Set<String>()
    @State private var showDeleteConfirm = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                if viewModel.items.isEmpty {
                    EmptyHistoryView(onGenerateFirst: {
                        router.navigateToEditor()
                    })
                } else {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 0),
                                GridItem(.flexible(), spacing: 0),
                                GridItem(.flexible(), spacing: 0)
                            ], spacing: 0) {
                                ForEach(viewModel.items) { item in
                                    HistoryItemCard(
                                        item: item,
                                        isSelecting: isSelecting,
                                        isSelected: selectedIds.contains(item.id)
                                    ) {
                                        if isSelecting {
                                            toggleSelection(for: item.id)
                                        } else {
                                            Haptics.impact(style: .light)
                                            selectedImage = item
                                        }
                                    }
                                }
                            }
                            .padding(1)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if isSelecting {
                            HStack {
                                Button(action: {
                                    if !selectedIds.isEmpty {
                                        showShareSheet = true
                                    }
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(selectedIds.isEmpty ? .textSecondary : .primaryAccent)
                                        .frame(width: 44, height: 44)
                                }
                                .disabled(selectedIds.isEmpty)
                                
                                Spacer()
                                
                                Button(action: {
                                    if !selectedIds.isEmpty {
                                        showDeleteConfirm = true
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(selectedIds.isEmpty ? .textSecondary : .primaryAccent)
                                        .frame(width: 44, height: 44)
                                }
                                .disabled(selectedIds.isEmpty)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(Color.backgroundBottom.opacity(0.98))
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History")
                        .font(.system(.largeTitle, design: .default, weight: .semibold))
                        .foregroundColor(.titleColor)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.items.isEmpty {
                        Button(action: {
                            if isSelecting {
                                Haptics.impact(style: .light)
                                isSelecting = false
                                selectedIds.removeAll()
                            } else {
                                Haptics.impact(style: .light)
                                isSelecting = true
                                selectedIds.removeAll()
                            }
                        }) {
                            Text(isSelecting ? "Cancel" : "Select")
                                .font(.system(.body, design: .default, weight: .medium))
                                .foregroundColor(.primaryAccent)
                        }
                    }
                }
            }
            .sheet(item: $selectedImage) { item in
                ImageDetailView(item: item)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: selectedImagesForShare())
            }
            .alert("Delete selected photos?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("OK", role: .destructive) {
                    Haptics.impact(style: .medium)
                    viewModel.deleteItems(withIDs: selectedIds)
                    selectedIds.removeAll()
                    isSelecting = false
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .onChange(of: viewModel.items.count) { newCount in
            if newCount == 0 {
                isSelecting = false
                selectedIds.removeAll()
            } else {
                selectedIds = selectedIds.filter { id in
                    viewModel.items.contains(where: { $0.id == id })
                }
            }
        }
    }

    private func toggleSelection(for id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
        Haptics.impact(style: .light)
    }
    
    private func selectedImagesForShare() -> [UIImage] {
        viewModel.items
            .filter { selectedIds.contains($0.id) }
            .compactMap { $0.editedImage }
    }
}

struct EmptyHistoryView: View {
    let onGenerateFirst: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.cardBackground)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.primaryAccent.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(.primaryAccent)
            }
            
            // Headline
            Text("Your transformations will appear here")
                .font(.system(.largeTitle, design: .default, weight: .semibold))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
            
            // Subtext
            // CTA Button
            MorphedButton(
                "Generate your first upgrade",
                icon: "sparkles",
                style: .primary
            ) {
                Haptics.impact(style: .medium)
                onGenerateFirst()
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.top, DesignSystem.Spacing.md)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

struct HistoryItemCard: View {
    let item: HistoryItem
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if let image = item.editedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.cardBackground)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                
                if isSelecting {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .primaryAccent : .white)
                        .padding(6)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
        }
        .overlay(
            Rectangle()
                .stroke(Color.white, lineWidth: 1)
        )
        .buttonStyle(PlainButtonStyle())
    }
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var items: [HistoryItem] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadHistory()
        startListeningForUpdates()
    }
    
    func addItem(_ item: HistoryItem) {
        items.insert(item, at: 0)
        saveHistory()
    }
    
    func clearHistory() {
        items.removeAll()
        saveHistory()
    }
    
    func deleteItems(withIDs ids: Set<String>) {
        guard !ids.isEmpty else { return }
        items.removeAll { ids.contains($0.id) }
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "morphed_history"),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            items = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "morphed_history")
        }
    }

    private func startListeningForUpdates() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadHistory()
            }
            .store(in: &cancellables)
    }
}

struct HistoryItem: Identifiable, Codable {
    let id: String
    let originalImageData: Data?
    let editedImageData: Data
    let mode: EditorViewModel.EditMode
    let createdAt: Date
    
    var originalImage: UIImage? {
        guard let data = originalImageData else { return nil }
        return UIImage(data: data)
    }
    
    var editedImage: UIImage? {
        return UIImage(data: editedImageData)
    }
    
    init(originalImage: UIImage?, editedImage: UIImage, mode: EditorViewModel.EditMode) {
        self.id = UUID().uuidString
        self.originalImageData = originalImage?.jpegData(compressionQuality: 0.8)
        self.editedImageData = editedImage.jpegData(compressionQuality: 0.8) ?? Data()
        self.mode = mode
        self.createdAt = Date()
    }
}

struct ImageDetailView: View {
    @Environment(\.dismiss) var dismiss
    let item: HistoryItem
    @State private var showingOriginal = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Image Toggle
                    Picker("View", selection: $showingOriginal) {
                        Text("Original").tag(true)
                        Text("Morphed").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Image Display
                    if let image = showingOriginal ? item.originalImage : item.editedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 500)
                            .padding(DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.xs)
                    }
                    
                    // Mode bubble (below image, keep layout stable)
                    ModePill(mode: item.mode)
                        .opacity(showingOriginal ? 0 : 1)
                        .frame(height: 24)
                        .padding(.top, -DesignSystem.Spacing.xl * 2)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        MorphedButton(
                            "Save",
                            icon: "square.and.arrow.down",
                            style: .primary
                        ) {
                            if let image = item.editedImage {
                                Task {
                                    try? await PhotoSaver.saveImage(image)
                                }
                            }
                        }
                        
                        MorphedButton(
                            "Share",
                            icon: "square.and.arrow.up",
                            style: .secondary
                        ) {
                            showShareSheet = true
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.bottom, DesignSystem.Spacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Image Detail")
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = item.editedImage {
                    ShareSheet(activityItems: [image])
                }
            }
        }
        .onAppear {
            let normalAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white
            ]
            let selectedAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor(Color.midnightNavy)
            ]
            UISegmentedControl.appearance().setTitleTextAttributes(normalAttributes, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(selectedAttributes, for: .selected)
        }
    }
}

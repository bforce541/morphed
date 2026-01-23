// morphed-ios/Morphed/Features/History/HistoryView.swift

import SwiftUI
import Combine

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @StateObject private var router = AppRouter.shared
    @State private var selectedImage: HistoryItem?
    
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
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2)
                        ], spacing: 2) {
                            ForEach(viewModel.items) { item in
                                HistoryItemCard(item: item) {
                                    Haptics.impact(style: .light)
                                    selectedImage = item
                                }
                            }
                        }
                        .padding(2)
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
                            Haptics.impact(style: .medium)
                            viewModel.clearHistory()
                        }) {
                            Text("Clear")
                                .font(.system(.body, design: .default, weight: .medium))
                                .foregroundColor(.primaryAccent)
                        }
                    }
                }
            }
            .sheet(item: $selectedImage) { item in
                ImageDetailView(item: item)
            }
        }
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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var items: [HistoryItem] = []
    
    init() {
        loadHistory()
    }
    
    func addItem(_ item: HistoryItem) {
        items.insert(item, at: 0)
        saveHistory()
    }
    
    func clearHistory() {
        items.removeAll()
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
                    }
                    
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
            .navigationTitle("Image Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
    }
}

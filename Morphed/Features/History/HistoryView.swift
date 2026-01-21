// morphed-ios/Morphed/Features/History/HistoryView.swift

import SwiftUI
import Combine

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var selectedImage: HistoryItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.midnightNavy.ignoresSafeArea()
                
                if viewModel.items.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(viewModel.items) { item in
                                HistoryItemCard(item: item) {
                                    selectedImage = item
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.items.isEmpty {
                        Button(action: {
                            viewModel.clearHistory()
                        }) {
                            Text("Clear")
                                .foregroundColor(.cyberCyan)
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
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.cyberCyan.opacity(0.3))
            
            Text("No History Yet")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.offWhite)
            
            Text("Your morphed images will appear here")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.offWhite.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

struct HistoryItemCard: View {
    let item: HistoryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let image = item.editedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.deepSlate)
                        .frame(height: 200)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Text(item.mode.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.midnightNavy)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: item.mode == .max ? [Color.cyberCyan, Color.electricBlue] : [Color.electricBlue, Color.cyberCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                        
                        Spacer()
                    }
                    .padding(8)
                }
            }
            .cornerRadius(12)
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
                Color.midnightNavy.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Image Toggle
                    Picker("View", selection: $showingOriginal) {
                        Text("Original").tag(true)
                        Text("Morphed").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Image Display
                    if let image = showingOriginal ? item.originalImage : item.editedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 500)
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            if let image = item.editedImage {
                                Task {
                                    try? await PhotoSaver.saveImage(image)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.midnightNavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.cyberCyan, Color.electricBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.midnightNavy)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.electricBlue, Color.cyberCyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Image Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.offWhite)
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


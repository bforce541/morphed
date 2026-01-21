// morphed-ios/Morphed/Features/Editor/EditorView.swift

import SwiftUI
import PhotosUI

struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @State private var showSettings = false
    @State private var showPaywall = false
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.midnightNavy.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Top bar
                        HStack {
                            Text("Morphed")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.offWhite)
                            
                            Spacer()
                            
                            if viewModel.selectedMode != nil {
                                ModePill(mode: viewModel.selectedMode!)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.offWhite.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Original Image Card
                        ImageCard(
                            title: "Original",
                            image: viewModel.originalImage,
                            isLoading: false,
                            onSelect: {
                                viewModel.showImagePicker = true
                            }
                        )
                        .padding(.horizontal, 20)
                        
                        // Mode Selector
                        if viewModel.originalImage != nil {
                            ModeSelector(
                                selectedMode: $viewModel.selectedMode,
                                onRequireUpgrade: {
                                    Haptics.notification(type: .warning)
                                    showPaywall = true
                                }
                            )
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Morph Button
                        if viewModel.originalImage != nil {
                            Button(action: {
                                Task {
                                    await viewModel.morphImage()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "sparkles")
                                        Text("Morph")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: viewModel.isLoading ? [Color.deepSlate] : [Color.electricBlue, Color.cyberCyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .disabled(viewModel.isLoading)
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Morphed Image Card
                        if viewModel.editedImage != nil {
                            ImageCard(
                                title: "Morphed",
                                image: viewModel.editedImage,
                                isLoading: false,
                                onSelect: nil
                            )
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            
                            // Save / Export Buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await viewModel.saveToPhotos()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save Preview")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.cyberCyan, Color.electricBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                }
                                
                                Button(action: {
                                    if FeatureGates.canExportHD(subscriptionManager) {
                                        UsageTracker.recordHDExport()
                                        Task {
                                            await viewModel.saveToPhotos()
                                        }
                                    } else {
                                        Haptics.notification(type: .warning)
                                        showPaywall = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Download HD (No Watermark)")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.midnightNavy)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.cyberCyan)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Paywall CTA
                        if viewModel.editedImage != nil {
                            Button(action: { showPaywall = true }) {
                                Text("Unlock Unlimited HD Morphs →")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.cyberCyan.opacity(0.8))
                                    .padding(.vertical, 12)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
                
                // Loading Overlay
                if viewModel.isLoading {
                    Color.midnightNavy.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .cyberCyan))
                            .scaleEffect(1.5)
                        
                        Text("Morphing your image...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.offWhite)
                    }
                    .padding(32)
                    .background(Color.deepSlate.opacity(0.95))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cyberCyan.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showImagePicker) {
                ImagePicker(selectedImage: $viewModel.originalImage)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .toast(message: viewModel.toastMessage, isPresented: $viewModel.showToast)
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
            .alert("Success", isPresented: $viewModel.showSaveSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Image saved to Photos")
            }
            .onChange(of: subscriptionManager.shouldPresentPaywall) { newValue in
                if newValue {
                    showPaywall = true
                    subscriptionManager.consumePaywallTrigger()
                }
            }
        }
    }
}

struct ModePill: View {
    let mode: EditorViewModel.EditMode
    
    var body: some View {
        Text(mode.displayName)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.midnightNavy)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: mode == .max ? [Color.cyberCyan, Color.electricBlue] : [Color.electricBlue, Color.cyberCyan],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .cyberCyan.opacity(0.5), radius: 4)
    }
}

struct ModeSelector: View {
    @Binding var selectedMode: EditorViewModel.EditMode?
    var onRequireUpgrade: (() -> Void)?
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(EditorViewModel.EditMode.allCases, id: \.self) { mode in
                Button(action: {
                    if mode == .max && SubscriptionManager.shared.shouldGateMaxMode() {
                        onRequireUpgrade?()
                        return
                    } else {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMode = mode
                        }
                        Haptics.impact(style: .light)
                    }
                }) {
                    Text(mode.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedMode == mode ? .midnightNavy : .offWhite.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Group {
                                if selectedMode == mode {
                                    LinearGradient(
                                        colors: mode == .max ? [Color.cyberCyan, Color.electricBlue] : [Color.electricBlue, Color.cyberCyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color.deepSlate
                                }
                            }
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMode == mode ? Color.clear : Color.cyberCyan.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: selectedMode == mode ? .cyberCyan.opacity(0.3) : .clear, radius: 8)
                }
            }
        }
    }
}

struct ImageCard: View {
    let title: String
    let image: UIImage?
    let isLoading: Bool
    let onSelect: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.offWhite)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.deepSlate)
                    .frame(height: 400)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyberCyan.opacity(0.2), lineWidth: 1)
                    )
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .frame(maxHeight: 400)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.cyberCyan.opacity(0.3))
                        
                        if onSelect != nil {
                            Text("Tap to select photo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.offWhite.opacity(0.6))
                        }
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyberCyan))
                }
            }
        }
        .onTapGesture {
            onSelect?()
        }
    }
}


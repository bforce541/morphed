// EditorView.swift

import SwiftUI

struct EditorView: View {
    @StateObject private var viewModel = EditorViewModel()
    @State private var showingOriginal = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Morphed")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    if let originalImage = viewModel.originalImage {
                        VStack(spacing: 10) {
                            Picker("View", selection: $showingOriginal) {
                                Text("Original").tag(true)
                                Text("Morphed").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            
                            Image(uiImage: showingOriginal ? originalImage : (viewModel.editedImage ?? originalImage))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 400)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 400)
                            .overlay(
                                Text("No image selected")
                                    .foregroundColor(.gray)
                            )
                            .padding(.horizontal)
                    }
                    
                    if viewModel.originalImage == nil {
                        ImagePicker(selectedImage: $viewModel.originalImage)
                            .padding(.horizontal)
                    }
                    
                    if viewModel.originalImage != nil {
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                ForEach(EditorViewModel.EditMode.allCases, id: \.self) { mode in
                                    Button(action: {
                                        viewModel.selectedMode = mode
                                    }) {
                                        Text(mode.displayName)
                                            .font(.headline)
                                            .foregroundColor(viewModel.selectedMode == mode ? .white : .blue)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(viewModel.selectedMode == mode ? Color.blue : Color.blue.opacity(0.1))
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
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
                                        Text("Morph")
                                            .font(.headline)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.isLoading ? Color.gray : Color.green)
                                .cornerRadius(10)
                            }
                            .disabled(viewModel.isLoading || viewModel.originalImage == nil)
                            .padding(.horizontal)
                            
                            if viewModel.editedImage != nil {
                                Button(action: {
                                    Task {
                                        await viewModel.saveToPhotos()
                                    }
                                }) {
                                    Text("Save to Photos")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.purple)
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarHidden(true)
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
        }
    }
}


// ImagePicker.swift

import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Text("Upload Photo")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        selectedImage = UIImage(data: data)
                    }
                }
            }
        }
    }
}


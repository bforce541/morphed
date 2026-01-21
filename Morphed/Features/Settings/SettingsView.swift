// morphed-ios/Morphed/Features/Settings/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var baseURL: String = UserDefaults.standard.string(forKey: "morphed_base_url") ?? "http://localhost:3000"
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.midnightNavy.ignoresSafeArea()
                
                Form {
                    Section(header: Text("API Configuration").foregroundColor(.offWhite.opacity(0.7))) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Base URL")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.offWhite)
                            
                            TextField("http://localhost:3000", text: $baseURL)
                                .textFieldStyle(.plain)
                                .foregroundColor(.offWhite)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .padding()
                                .background(Color.deepSlate)
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                        
                        Text("For iOS Simulator: use http://localhost:3000\nFor physical device: use your computer's LAN IP (e.g., http://192.168.1.100:3000)")
                            .font(.system(size: 12))
                            .foregroundColor(.offWhite.opacity(0.5))
                    }
                    .listRowBackground(Color.deepSlate)
                    
                    Section {
                        Button(action: {
                            UserDefaults.standard.set(baseURL, forKey: "morphed_base_url")
                            Haptics.notification(type: .success)
                            dismiss()
                        }) {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.midnightNavy)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [Color.electricBlue, Color.cyberCyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showResetAlert = true
                        }) {
                            Text("Reset to Default")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.offWhite.opacity(0.7))
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.offWhite)
                }
            }
            .alert("Reset to Default?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset") {
                    baseURL = "http://localhost:3000"
                    UserDefaults.standard.removeObject(forKey: "morphed_base_url")
                    Haptics.notification(type: .success)
                }
            } message: {
                Text("This will reset the base URL to http://localhost:3000")
            }
        }
    }
}


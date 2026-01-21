// morphed-ios/Morphed/Core/Utils/ToastView.swift

import SwiftUI

struct ToastModifier: ViewModifier {
    let message: String?
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented, let message = message {
                VStack {
                    Spacer()
                    
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.offWhite)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.deepSlate)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyberCyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: .cyberCyan.opacity(0.3), radius: 10)
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onChange(of: isPresented) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isPresented = false
                    }
                }
            }
        }
    }
}

extension View {
    func toast(message: String?, isPresented: Binding<Bool>) -> some View {
        modifier(ToastModifier(message: message, isPresented: isPresented))
    }
}


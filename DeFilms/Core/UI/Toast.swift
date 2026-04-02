//
//  Toast.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct ToastItem: Identifiable, Equatable {
    enum Style {
        case info
        case success
        case error

        var backgroundColor: Color {
            switch self {
            case .info: return Color.black.opacity(0.8)
            case .success: return Color.green.opacity(0.85)
            case .error: return Color.red.opacity(0.85)
            }
        }
    }

    let id = UUID()
    let message: String
    let style: Style
}

struct ToastView: View {
    let item: ToastItem

    var body: some View {
        Text(item.message)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(item.style.backgroundColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(radius: 6)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var item: ToastItem?
    let duration: TimeInterval

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let item {
                    ToastView(item: item)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: item) { newValue in
                guard newValue != nil else { return }
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    item = nil
                }
            }
    }
}

extension View {
    func toast(item: Binding<ToastItem?>, duration: TimeInterval = 1.2) -> some View {
        modifier(ToastModifier(item: item, duration: duration))
    }
}

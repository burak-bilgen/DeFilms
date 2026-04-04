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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(item.style.backgroundColor)
            )
            .foregroundColor(.white)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 18, x: 0, y: 10)
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
                        .padding(.bottom, 84)
                        .transition(
                            .asymmetric(
                                insertion: .offset(y: 18).combined(with: .opacity).combined(with: .scale(scale: 0.94, anchor: .bottom)),
                                removal: .offset(y: 10).combined(with: .opacity).combined(with: .scale(scale: 0.98, anchor: .bottom))
                            )
                        )
                }
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.86), value: item?.id)
            .task(id: item?.id) {
                guard item != nil else { return }

                do {
                    try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.24)) {
                            item = nil
                        }
                    }
                } catch {
                    return
                }
            }
    }
}

extension View {
    func toast(item: Binding<ToastItem?>, duration: TimeInterval = 1.2) -> some View {
        modifier(ToastModifier(item: item, duration: duration))
    }
}

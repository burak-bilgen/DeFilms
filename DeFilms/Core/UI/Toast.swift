//
//  Toast.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Lottie
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
    @Binding var overlayAnimation: OverlayAnimation?
    let duration: TimeInterval

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let item {
                    ToastView(item: item)
                        .padding(.bottom, 84)
                        .transition(
                            .asymmetric(
                                insertion: .offset(y: 24).combined(with: .opacity).combined(with: .scale(scale: 0.96, anchor: .bottom)),
                                removal: .offset(y: 12).combined(with: .opacity)
                            )
                        )
                }
            }
            .overlay {
                if let overlayAnimation {
                    OverlayAnimationView(animationName: overlayAnimation.animationName)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.88), value: item)
            .animation(.easeInOut(duration: 0.24), value: overlayAnimation)
            .onChange(of: item) { newValue in
                guard newValue != nil else { return }
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            item = nil
                        }
                    }
                }
            }
            .onChange(of: overlayAnimation) { newValue in
                guard newValue != nil else { return }
                Task {
                    try? await Task.sleep(nanoseconds: 1_300_000_000)
                    await MainActor.run {
                        withAnimation(.easeOut(duration: 0.2)) {
                            overlayAnimation = nil
                        }
                    }
                }
            }
    }
}

extension View {
    func toast(
        item: Binding<ToastItem?>,
        overlayAnimation: Binding<OverlayAnimation?> = .constant(nil),
        duration: TimeInterval = 1.2
    ) -> some View {
        modifier(ToastModifier(item: item, overlayAnimation: overlayAnimation, duration: duration))
    }
}

struct OverlayAnimation: Identifiable, Equatable {
    enum Kind: Equatable {
        case success

        var animationName: String {
            switch self {
            case .success:
                return "success"
            }
        }
    }

    let id = UUID()
    let kind: Kind

    var animationName: String {
        kind.animationName
    }
}

private struct OverlayAnimationView: View {
    let animationName: String

    var body: some View {
        LottieOverlayView(animationName: animationName)
            .frame(width: 180, height: 180)
            .padding(.bottom, 120)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

private struct LottieOverlayView: UIViewRepresentable {
    let animationName: String

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        let animationView = LottieAnimationView(name: animationName)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.play()

        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let animationView = uiView.subviews.first as? LottieAnimationView else { return }
        animationView.currentProgress = 0
        animationView.play()
    }
}

//
//  FavoritesModalShell.swift
//  DeFilms
//

import SwiftUI

struct FavoritesModalShell<Content: View>: View {
    let regularMaxWidth: CGFloat
    let accessibilityMaxWidth: CGFloat
    let content: (@escaping () -> Void) -> Content

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var isPresented = false
    @State private var isBackdropVisible = false
    @State private var isDismissing = false

    var body: some View {
        ZStack {
            Color.black
                .opacity(isBackdropVisible ? 0.28 : 0)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissAnimated()
                }

            content(dismissAnimated)
                .padding(AppSpacing.lg)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? accessibilityMaxWidth : regularMaxWidth)
                .background(modalBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                        .stroke(AppPalette.border.opacity(1.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.24), radius: 28, x: 0, y: 18)
                .padding(.horizontal, AppSpacing.lg)
                .scaleEffect(isPresented ? 1 : 0.92)
                .opacity(isPresented ? 1 : 0)
                .offset(y: isPresented ? 0 : 16)
        }
        .presentationBackground(.clear)
        .animation(AppAnimation.emphasizedSpring, value: isPresented)
        .task {
            isPresented = true

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(220))
                guard !isDismissing else { return }
                withAnimation(.easeOut(duration: 0.18)) {
                    isBackdropVisible = true
                }
            }
        }
    }

    private var modalBackground: some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
            .fill(AppPalette.screenBackground)
    }

    private func dismissAnimated() {
        guard !isDismissing else { return }
        isDismissing = true

        withAnimation(.easeIn(duration: 0.12)) {
            isBackdropVisible = false
        }

        withAnimation(AppAnimation.emphasizedSpring) {
            isPresented = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            dismiss()
        }
    }
}

//
//  MoviesMessageView.swift
//  DeFilms
//

import SwiftUI

struct MoviesMessageView: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let buttonTitle, let action {
                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
            }
        }
        .padding(AppSpacing.xl)
        .appCardSurface(cornerRadius: AppCornerRadius.md)
        .accessibilityElement(children: .contain)
    }
}

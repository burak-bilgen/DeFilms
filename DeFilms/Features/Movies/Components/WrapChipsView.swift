//
//  WrapChipsView.swift
//  DeFilms
//

import SwiftUI

struct WrapChipsView: View {
    let items: [String]
    var inverted: Bool = false

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(items.prefix(3), id: \.self) { item in
                    chip(item)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(Array(Array(items.prefix(4)).chunked(into: 2).enumerated()), id: \.offset) { entry in
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(entry.element, id: \.self) { item in
                            chip(item)
                        }
                    }
                }
            }
        }
    }

    private func chip(_ item: String) -> some View {
        Text(item)
            .font(.caption.weight(.medium))
            .foregroundStyle(inverted ? .white.opacity(0.92) : .secondary)
            .padding(.horizontal, AppSpacing.sm - 2)
            .frame(height: 28)
            .background(inverted ? Color.white.opacity(0.16) : AppPalette.cardBackground)
            .clipShape(Capsule())
    }
}

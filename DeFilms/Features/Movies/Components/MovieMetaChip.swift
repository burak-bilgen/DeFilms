//
//  MovieMetaChip.swift
//  DeFilms
//

import SwiftUI

enum MovieMetaChipStyle {
    case light
    case dark
}

struct MovieMetaChip: View {
    let title: String
    let systemImage: String
    let style: MovieMetaChipStyle

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(style == .dark ? .white : .primary)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(style == .dark ? Color.white.opacity(0.18) : Color(.secondarySystemBackground))
            .clipShape(Capsule())
    }
}

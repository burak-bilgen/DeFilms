
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
            .padding(.horizontal, AppSpacing.sm - 2)
            .frame(height: AppDimension.chipHeight)
            .background(style == .dark ? Color.white.opacity(0.18) : AppPalette.cardBackground)
            .clipShape(Capsule())
    }
}

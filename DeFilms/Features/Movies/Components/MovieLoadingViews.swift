
import SwiftUI

struct SkeletonBlock: View {
    var cornerRadius: CGFloat = AppCornerRadius.sm
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shimmerOffset: CGFloat = -1.2

    var body: some View {
        GeometryReader { geometry in
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemGray5),
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    shape
                        .fill(Color.white.opacity(0.55))
                        .mask {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .clear,
                                            .white,
                                            .clear
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: geometry.size.width * 0.4)
                                .rotationEffect(.degrees(14))
                                .offset(x: geometry.size.width * shimmerOffset)
                        }
                }
                .clipShape(shape)
                .onAppear {
                    guard !reduceMotion else { return }
                    shimmerOffset = -1.2
                    withAnimation(.linear(duration: 1.15).repeatForever(autoreverses: false)) {
                        shimmerOffset = 1.2
                    }
                }
                .onDisappear {
                    shimmerOffset = -1.2
                }
        }
        .accessibilityHidden(true)
    }
}

struct MovieCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SkeletonBlock(cornerRadius: AppCornerRadius.md)
                .aspectRatio(2.0 / 3.0, contentMode: .fit)

            VStack(alignment: .leading, spacing: AppSpacing.xs - 2) {
                SkeletonBlock(cornerRadius: 6)
                    .frame(height: 14)

                SkeletonBlock(cornerRadius: 6)
                    .frame(width: 72, height: 12)
            }
            .padding(.horizontal, 2)
        }
        .accessibilityHidden(true)
    }
}

struct MovieSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SkeletonBlock(cornerRadius: 6)
                .frame(width: 110, height: 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<5, id: \.self) { _ in
                        MovieCardSkeletonView()
                            .frame(width: AppDimension.posterRailWidth)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct MovieGridSkeletonView: View {
    let columns: [GridItem]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.lg - 2) {
            ForEach(0..<6, id: \.self) { _ in
                MovieCardSkeletonView()
            }
        }
        .accessibilityHidden(true)
    }
}

struct MovieDetailSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                SkeletonBlock(cornerRadius: 0)
                    .frame(height: 420)

                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonBlock(cornerRadius: 18)
                                .frame(height: 82)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SkeletonBlock(cornerRadius: 8)
                            .frame(width: 90, height: 12)

                        ForEach(0..<5, id: \.self) { index in
                            SkeletonBlock(cornerRadius: 8)
                                .frame(height: 14)
                                .padding(.trailing, index == 4 ? 56 : 0)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SkeletonBlock(cornerRadius: 8)
                            .frame(width: 72, height: 12)
                        ForEach(0..<2, id: \.self) { index in
                            SkeletonBlock(cornerRadius: 8)
                                .frame(height: 14)
                                .padding(.trailing, index == 1 ? 78 : 0)
                        }
                    }
                }
                .padding(AppSpacing.xl)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous))
                .padding(.horizontal, AppSpacing.lg - 2)
            }
        }
        .ignoresSafeArea(edges: .top)
        .accessibilityHidden(true)
    }
}

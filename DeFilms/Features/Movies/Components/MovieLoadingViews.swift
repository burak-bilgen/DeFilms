//
//  MovieLoadingViews.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct SkeletonBlock: View {
    var cornerRadius: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.18),
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shimmering()
    }
}

struct MovieCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SkeletonBlock(cornerRadius: 16)
                .aspectRatio(2.0 / 3.0, contentMode: .fit)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonBlock(cornerRadius: 6)
                    .frame(height: 14)

                SkeletonBlock(cornerRadius: 6)
                    .frame(width: 72, height: 12)
            }
            .padding(.horizontal, 2)
        }
    }
}

struct MovieSectionSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SkeletonBlock(cornerRadius: 6)
                .frame(width: 110, height: 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(0..<5, id: \.self) { _ in
                        MovieCardSkeletonView()
                            .frame(width: 146)
                    }
                }
            }
        }
    }
}

struct MovieGridSkeletonView: View {
    let columns: [GridItem]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 18) {
            ForEach(0..<6, id: \.self) { _ in
                MovieCardSkeletonView()
            }
        }
    }
}

struct MovieDetailSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SkeletonBlock(cornerRadius: 0)
                    .frame(height: 420)

                VStack(alignment: .leading, spacing: 20) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                .padding(24)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 18)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.35),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geometry.size.width * 1.4)
                    .rotationEffect(.degrees(12))
                    .offset(x: isAnimating ? geometry.size.width * 1.6 : -geometry.size.width * 1.6)
                    .blendMode(.screen)
                    .animation(
                        .linear(duration: 1.15).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                }
                .clipped()
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

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
            .redacted(reason: .placeholder)
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
                            .frame(width: 150)
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
            VStack(spacing: 0) {
                SkeletonBlock(cornerRadius: 0)
                    .frame(height: 360)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 18) {
                        SkeletonBlock(cornerRadius: 20)
                            .frame(width: 118, height: 177)

                        VStack(alignment: .leading, spacing: 10) {
                            SkeletonBlock(cornerRadius: 8)
                                .frame(height: 28)

                            SkeletonBlock(cornerRadius: 8)
                                .frame(width: 140, height: 18)

                            HStack(spacing: 8) {
                                SkeletonBlock(cornerRadius: 999)
                                .frame(width: 82, height: 32)

                                SkeletonBlock(cornerRadius: 999)
                                    .frame(width: 82, height: 32)
                            }

                            SkeletonBlock(cornerRadius: 999)
                                .frame(width: 140, height: 44)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SkeletonBlock(cornerRadius: 8)
                            .frame(width: 100, height: 18)

                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonBlock(cornerRadius: 8)
                                .frame(height: 14)
                        }
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .padding(.horizontal, 16)
                .offset(y: -42)
                .padding(.bottom, -42)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

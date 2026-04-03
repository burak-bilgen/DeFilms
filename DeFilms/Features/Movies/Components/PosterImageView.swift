//
//  PosterImageView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI
import UIKit

struct PosterImageView: View {
    let url: URL?
    let cornerRadius: CGFloat
    let placeholderSystemImage: String

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else if isLoading {
                loadingPlaceholder
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: url) {
            await loadImage()
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
            Image(systemName: placeholderSystemImage)
                .foregroundColor(.gray)
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.14),
                            Color.gray.opacity(0.22),
                            Color.gray.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shimmering()

            VStack(spacing: 8) {
                Image(systemName: placeholderSystemImage)
                    .font(.title2)
                    .foregroundStyle(.secondary.opacity(0.75))
            }
        }
    }

    private func loadImage() async {
        guard let url else {
            image = nil
            isLoading = false
            return
        }

        if let cachedImage = PosterImageMemoryCache.shared.image(for: url) {
            image = cachedImage
            isLoading = false
            return
        }

        image = nil
        isLoading = true

        do {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 30

            let (data, _) = try await URLSession.shared.data(for: request)

            guard !Task.isCancelled, let loadedImage = UIImage(data: data) else {
                isLoading = false
                return
            }

            PosterImageMemoryCache.shared.insert(loadedImage, for: url)
            image = loadedImage
        } catch {
            image = nil
        }

        isLoading = false
    }
}

private final class PosterImageMemoryCache {
    static let shared = PosterImageMemoryCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 300
        cache.totalCostLimit = 80 * 1024 * 1024
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

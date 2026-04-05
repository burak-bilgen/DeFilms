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
    @State private var isLoading: Bool
    @State private var loadedURL: URL?
    @State private var retrySeed = 0

    init(url: URL?, cornerRadius: CGFloat, placeholderSystemImage: String) {
        self.url = url
        self.cornerRadius = cornerRadius
        self.placeholderSystemImage = placeholderSystemImage
        _isLoading = State(initialValue: false)
    }

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
        .task(id: taskIdentifier) {
            await loadImage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .connectivityDidRestore)) { _ in
            guard image == nil, url != nil else { return }
            retrySeed += 1
        }
    }

    private var taskIdentifier: String {
        "\(url?.absoluteString ?? "nil")-\(retrySeed)"
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
        SkeletonBlock(cornerRadius: cornerRadius)
    }

    private func loadImage() async {
        guard let url else {
            image = nil
            loadedURL = nil
            isLoading = false
            return
        }

        if loadedURL == url, image != nil {
            return
        }

        if let cachedImage = await PosterImagePipeline.shared.cachedImage(for: url) {
            loadedURL = url
            image = cachedImage
            isLoading = false
            return
        }

        image = nil
        loadedURL = nil
        isLoading = true

        guard await ConnectivityStateStore.shared.connected() else {
            isLoading = false
            return
        }

        guard let loadedImage = await PosterImagePipeline.shared.image(for: url) else {
            isLoading = false
            image = nil
            return
        }

        withAnimation(.easeOut(duration: 0.24)) {
            loadedURL = url
            image = loadedImage
        }

        isLoading = false
    }
}

actor PosterImagePipeline {
    static let shared = PosterImagePipeline()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    private var inFlightTasks: [URL: Task<UIImage?, Never>] = [:]

    private init() {
        cache.countLimit = 300
        cache.totalCostLimit = 80 * 1024 * 1024
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 45
        configuration.waitsForConnectivity = true
        session = URLSession(configuration: configuration)
    }

    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func image(for url: URL) async -> UIImage? {
        if let cachedImage = cachedImage(for: url) {
            return cachedImage
        }

        if let task = inFlightTasks[url] {
            return await task.value
        }

        let task = Task<UIImage?, Never> {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 20

            do {
                let (data, _) = try await self.session.data(for: request)
                guard let loadedImage = UIImage(data: data) else { return nil }
                await self.insert(loadedImage, for: url)
                return loadedImage
            } catch {
                return nil
            }
        }

        inFlightTasks[url] = task
        let image = await task.value
        inFlightTasks[url] = nil
        return image
    }

    func prefetch(urls: [URL]) {
        for url in urls {
            guard cachedImage(for: url) == nil, inFlightTasks[url] == nil else { continue }

            let task = Task<UIImage?, Never> {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 20

                do {
                    let (data, _) = try await self.session.data(for: request)
                    guard let loadedImage = UIImage(data: data) else { return nil }
                    await self.insert(loadedImage, for: url)
                    return loadedImage
                } catch {
                    return nil
                }
            }

            inFlightTasks[url] = task

            Task {
                _ = await task.value
                await self.finishPrefetch(for: url)
            }
        }
    }

    private func finishPrefetch(for url: URL) async {
        inFlightTasks[url] = nil
    }

    private func insert(_ image: UIImage, for url: URL) async {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

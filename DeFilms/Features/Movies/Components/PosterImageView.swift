
import SwiftUI
import ImageIO
import UIKit

struct PosterImageView: View {
    let url: URL?
    let cornerRadius: CGFloat
    let placeholderSystemImage: String
    let maxPixelSize: CGFloat

    @State private var image: UIImage?
    @State private var isLoading: Bool
    @State private var loadedURL: URL?
    @State private var retrySeed = 0

    init(
        url: URL?,
        cornerRadius: CGFloat,
        placeholderSystemImage: String,
        maxPixelSize: CGFloat = 700
    ) {
        self.url = url
        self.cornerRadius = cornerRadius
        self.placeholderSystemImage = placeholderSystemImage
        self.maxPixelSize = maxPixelSize
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
        "\(url?.absoluteString ?? "nil")-\(Int(maxPixelSize))-\(retrySeed)"
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

        if let cachedImage = await PosterImagePipeline.shared.cachedImage(for: url, maxPixelSize: maxPixelSize) {
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

        guard let loadedImage = await PosterImagePipeline.shared.image(for: url, maxPixelSize: maxPixelSize) else {
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

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession
    private var inFlightTasks: [String: Task<UIImage?, Never>] = [:]

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

    func cachedImage(for url: URL, maxPixelSize: CGFloat = 700) -> UIImage? {
        cache.object(forKey: cacheKey(for: url, maxPixelSize: maxPixelSize) as NSString)
    }

    func image(for url: URL, maxPixelSize: CGFloat = 700) async -> UIImage? {
        let key = cacheKey(for: url, maxPixelSize: maxPixelSize)

        if let cachedImage = cachedImage(for: url, maxPixelSize: maxPixelSize) {
            return cachedImage
        }

        if let task = inFlightTasks[key] {
            return await task.value
        }

        let task = Task<UIImage?, Never> {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            request.timeoutInterval = 20

            do {
                let (data, _) = try await self.session.data(for: request)
                guard let loadedImage = Self.downsampledImage(from: data, maxPixelSize: maxPixelSize) else { return nil }
                await self.insert(loadedImage, for: key)
                return loadedImage
            } catch {
                return nil
            }
        }

        inFlightTasks[key] = task
        let image = await task.value
        inFlightTasks[key] = nil
        return image
    }

    func prefetch(urls: [URL]) {
        for url in urls {
            let key = cacheKey(for: url, maxPixelSize: 700)
            guard cachedImage(for: url) == nil, inFlightTasks[key] == nil else { continue }

            let task = Task<UIImage?, Never> {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 20

                do {
                    let (data, _) = try await self.session.data(for: request)
                    guard let loadedImage = Self.downsampledImage(from: data, maxPixelSize: 700) else { return nil }
                    await self.insert(loadedImage, for: key)
                    return loadedImage
                } catch {
                    return nil
                }
            }

            inFlightTasks[key] = task

            Task {
                _ = await task.value
                await self.finishPrefetch(forKey: key)
            }
        }
    }

    private func finishPrefetch(forKey key: String) async {
        inFlightTasks[key] = nil
    }

    private func insert(_ image: UIImage, for key: String) async {
        let pixelWidth = Int(image.size.width * image.scale)
        let pixelHeight = Int(image.size.height * image.scale)
        let cost = pixelWidth * pixelHeight * 4
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    private func cacheKey(for url: URL, maxPixelSize: CGFloat) -> String {
        "\(url.absoluteString)#\(Int(maxPixelSize.rounded()))"
    }

    private static func downsampledImage(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, options) else { return nil }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxPixelSize.rounded()))
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
        return UIImage(cgImage: image)
    }
}

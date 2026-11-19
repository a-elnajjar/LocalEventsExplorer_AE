//
//  ImageLoader.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Two-level image cache: decoded images in memory (NSCache) and downloaded data on disk (URLCache).

import UIKit

nonisolated protocol ImageLoading: Sendable {
    func image(for url: URL) async throws -> UIImage
}

/// Loads images with memory and disk caching.
nonisolated final class ImageLoader: ImageLoading, @unchecked Sendable {
    private let session: URLSession
    private let memoryCache = NSCache<NSURL, UIImage>()

    init() {
        let configuration = URLSessionConfiguration.default
        // Disk cache lets images load offline too, once downloaded once.
        configuration.urlCache = URLCache(memoryCapacity: 0, diskCapacity: AppConfig.imageDiskCacheCapacityBytes)
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: configuration)
        // NSCache also evicts automatically under memory pressure.
        memoryCache.countLimit = AppConfig.imageMemoryCacheCountLimit
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }
        let (data, _) = try await session.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        memoryCache.setObject(image, forKey: url as NSURL)
        return image
    }
}

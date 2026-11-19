//
//  CachedAsyncImage.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  AsyncImage replacement that loads through the app's cached ImageLoader.

import SwiftUI

extension EnvironmentValues {
    @Entry var imageLoader: any ImageLoading = ImageLoader()
}

struct CachedAsyncImage: View {
    let url: URL?

    @Environment(\.imageLoader) private var loader
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.2)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .task(id: url) {
            guard let url else { return }
            image = try? await loader.image(for: url)
        }
    }
}

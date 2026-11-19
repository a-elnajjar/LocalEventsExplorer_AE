//
//  ModelContainer+App.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Single place that defines the app's SwiftData schema (used by the app, previews and tests).

import SwiftData

extension ModelContainer {
    static func app(inMemory: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: CachedEvent.self, Bookmark.self, configurations: config)
    }
}

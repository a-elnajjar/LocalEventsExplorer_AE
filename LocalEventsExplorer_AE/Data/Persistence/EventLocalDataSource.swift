//
//  EventLocalDataSource.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Persists last-fetched events in SwiftData so the app works offline and across launches.

import Foundation
import SwiftData

@MainActor
protocol EventLocalDataSource {
    func loadEvents() throws -> [Event]
    func save(_ events: [Event], fetchedAt: Date) throws
    func lastFetchDate() throws -> Date?

    func bookmarkedIDs() throws -> Set<String>
    func isBookmarked(_ eventID: String) throws -> Bool
    @discardableResult
    func toggleBookmark(_ eventID: String) throws -> Bool
}

@MainActor
final class SwiftDataEventLocalDataSource: EventLocalDataSource {
    private let context: ModelContext
    /// Retained so the context stays valid when this data source owns its container.
    private let container: ModelContainer?

    init(context: ModelContext) {
        self.context = context
        self.container = nil
    }

    init(container: ModelContainer) {
        self.context = container.mainContext
        self.container = container
    }

    func loadEvents() throws -> [Event] {
        let descriptor = FetchDescriptor<CachedEvent>(sortBy: [SortDescriptor(\.startTime)])
        return try context.fetch(descriptor).map(\.asEvent)
    }

    func save(_ events: [Event], fetchedAt: Date) throws {
        try context.delete(model: CachedEvent.self)
        for event in events {
            context.insert(CachedEvent(event, fetchedAt: fetchedAt))
        }
        try context.save()
    }

    func lastFetchDate() throws -> Date? {
        var descriptor = FetchDescriptor<CachedEvent>(sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first?.fetchedAt
    }

    // MARK: - Bookmarks

    func bookmarkedIDs() throws -> Set<String> {
        Set(try context.fetch(FetchDescriptor<Bookmark>()).map(\.eventID))
    }

    func isBookmarked(_ eventID: String) throws -> Bool {
        try bookmark(for: eventID) != nil
    }

    @discardableResult
    func toggleBookmark(_ eventID: String) throws -> Bool {
        let isNowBookmarked: Bool
        if let existing = try bookmark(for: eventID) {
            context.delete(existing)
            isNowBookmarked = false
        } else {
            context.insert(Bookmark(eventID: eventID))
            isNowBookmarked = true
        }
        try context.save()
        return isNowBookmarked
    }

    private func bookmark(for eventID: String) throws -> Bookmark? {
        var descriptor = FetchDescriptor<Bookmark>(predicate: #Predicate { $0.eventID == eventID })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}

#if DEBUG
extension SwiftDataEventLocalDataSource {
    /// In-memory store for SwiftUI previews.
    static var preview: SwiftDataEventLocalDataSource {
        do {
            return SwiftDataEventLocalDataSource(container: try .app(inMemory: true))
        } catch {
            fatalError("Could not create preview store: \(error)")
        }
    }
}
#endif

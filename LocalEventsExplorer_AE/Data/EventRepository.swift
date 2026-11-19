//
//  EventRepository.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Single source of truth for events: offline-first over SwiftData, synced from the remote API with a TTL.

import Foundation

@MainActor
protocol EventRepository {
    /// Returns events, using the cache if it's still fresh.
    func events(forceRefresh: Bool) async throws -> [Event]
    /// Returns whatever is currently cached, without touching the network.
    func cachedEvents() throws -> [Event]

    func bookmarkedIDs() throws -> Set<String>
    func isBookmarked(_ eventID: String) throws -> Bool
    @discardableResult
    func toggleBookmark(_ eventID: String) throws -> Bool
}

@MainActor
final class DefaultEventRepository: EventRepository {
    private let remote: EventRemoteDataSource
    private let local: EventLocalDataSource
    private let ttl: TimeInterval
    private let now: () -> Date

    init(
        remote: EventRemoteDataSource = DefaultEventRemoteDataSource(),
        local: EventLocalDataSource,
        ttl: TimeInterval = AppConfig.cacheTTL,
        now: @escaping () -> Date = Date.init
    ) {
        self.remote = remote
        self.local = local
        self.ttl = ttl
        self.now = now
    }

    func events(forceRefresh: Bool = false) async throws -> [Event] {
        if !forceRefresh, let lastFetch = try local.lastFetchDate(), now().timeIntervalSince(lastFetch) < ttl {
            return try local.loadEvents()
        }
        let events = try await remote.fetchEvents()
        try local.save(events, fetchedAt: now())
        return try local.loadEvents()
    }

    func cachedEvents() throws -> [Event] {
        try local.loadEvents()
    }

    // MARK: - Bookmarks

    func bookmarkedIDs() throws -> Set<String> {
        try local.bookmarkedIDs()
    }

    func isBookmarked(_ eventID: String) throws -> Bool {
        try local.isBookmarked(eventID)
    }

    @discardableResult
    func toggleBookmark(_ eventID: String) throws -> Bool {
        try local.toggleBookmark(eventID)
    }
}

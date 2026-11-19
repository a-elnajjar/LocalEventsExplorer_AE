//
//  EventLocalDataSourceTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Tests for the SwiftData-backed local data source, using an in-memory store.

import Foundation
@testable import LocalEventsExplorer_AE
import SwiftData
import Testing

@Suite("EventLocalDataSource")
@MainActor
struct EventLocalDataSourceTests {
    private let container: ModelContainer
    private let local: SwiftDataEventLocalDataSource

    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: CachedEvent.self, Bookmark.self, configurations: config)
        local = SwiftDataEventLocalDataSource(context: container.mainContext)
    }

    @Test("Empty store returns no events and no last fetch date")
    func emptyStore() throws {
        #expect(try local.loadEvents().isEmpty)
        #expect(try local.lastFetchDate() == nil)
    }

    @Test("Saved events are loaded back sorted by start time, with the fetch date")
    func saveAndLoad() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_000_000)
        let later = makeEvent(id: "b", start: 2_000)
        let earlier = makeEvent(id: "a", start: 1_000)

        try local.save([later, earlier], fetchedAt: fetchedAt)

        #expect(try local.loadEvents() == [earlier, later])
        #expect(try local.lastFetchDate() == fetchedAt)
    }

    @Test("Saving replaces previously stored events")
    func saveReplacesOldEvents() throws {
        try local.save([makeEvent(id: "old", start: 1_000)], fetchedAt: Date(timeIntervalSince1970: 1))
        let newEvent = makeEvent(id: "new", start: 2_000)
        let newFetch = Date(timeIntervalSince1970: 2)

        try local.save([newEvent], fetchedAt: newFetch)

        #expect(try local.loadEvents() == [newEvent])
        #expect(try local.lastFetchDate() == newFetch)
    }

    // MARK: - Bookmarks

    @Test("Toggling a bookmark adds it, then removes it")
    func toggleBookmark() throws {
        #expect(try !local.isBookmarked("a"))

        #expect(try local.toggleBookmark("a") == true)
        #expect(try local.isBookmarked("a"))
        #expect(try local.bookmarkedIDs() == ["a"])

        #expect(try local.toggleBookmark("a") == false)
        #expect(try !local.isBookmarked("a"))
        #expect(try local.bookmarkedIDs().isEmpty)
    }

    @Test("Bookmarks survive replacing the stored events")
    func bookmarksSurviveSave() throws {
        try local.save([makeEvent(id: "a", start: 1_000)], fetchedAt: Date(timeIntervalSince1970: 1))
        try local.toggleBookmark("a")

        try local.save([makeEvent(id: "a", start: 1_000)], fetchedAt: Date(timeIntervalSince1970: 2))

        #expect(try local.isBookmarked("a"))
    }

    // MARK: - Helpers

    private func makeEvent(id: String, start: TimeInterval) -> Event {
        Event(
            id: id,
            title: "Event \(id)",
            locationName: "Toronto",
            latitude: 43.65,
            longitude: -79.38,
            startTime: Date(timeIntervalSince1970: start),
            imageURL: URL(string: "https://example.com/\(id).jpg")
        )
    }
}

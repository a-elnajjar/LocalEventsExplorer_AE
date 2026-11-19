//
//  EventRepositoryTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Tests for DefaultEventRepository: TTL cache over SwiftData, with a stubbed remote.

import Foundation
@testable import LocalEventsExplorer_AE
import Testing

@Suite("EventRepository")
@MainActor
struct EventRepositoryTests {
    private let sampleEvent = Event(
        id: "1", title: "T", locationName: "L",
        latitude: 1, longitude: 1,
        startTime: Date(timeIntervalSince1970: 0), imageURL: nil
    )
    private let clock = Clock()

    @Test("First call fetches from the remote and saves to SwiftData")
    func firstCallFetchesAndPersists() async throws {
        let local = try TestSupport.inMemoryLocal()
        let remote = StubEventRemoteDataSource(result: .success([sampleEvent]))
        let repository = DefaultEventRepository(remote: remote, local: local, now: { self.clock.now })

        let events = try await repository.events(forceRefresh: false)

        #expect(events == [sampleEvent])
        #expect(remote.fetchCount == 1)
        #expect(try local.loadEvents() == events)
        #expect(try local.lastFetchDate() == clock.now)
    }

    @Test("Within the TTL, stored events are returned without a network call")
    func servesStoreWithinTTL() async throws {
        let local = try TestSupport.inMemoryLocal()
        let remote = StubEventRemoteDataSource(result: .success([sampleEvent]))
        let repository = DefaultEventRepository(remote: remote, local: local, now: { self.clock.now })
        let first = try await repository.events(forceRefresh: false)

        clock.now = clock.now.addingTimeInterval(AppConfig.cacheTTL - 1)
        let second = try await repository.events(forceRefresh: false)

        #expect(second == first)
        #expect(remote.fetchCount == 1)
    }

    @Test("After the TTL expires, events are fetched again")
    func refetchesAfterTTL() async throws {
        let local = try TestSupport.inMemoryLocal()
        let remote = StubEventRemoteDataSource(result: .success([sampleEvent]))
        let repository = DefaultEventRepository(remote: remote, local: local, now: { self.clock.now })
        _ = try await repository.events(forceRefresh: false)

        clock.now = clock.now.addingTimeInterval(AppConfig.cacheTTL)
        _ = try await repository.events(forceRefresh: false)

        #expect(remote.fetchCount == 2)
    }

    @Test("forceRefresh bypasses a fresh store")
    func forceRefreshBypassesStore() async throws {
        let local = try TestSupport.inMemoryLocal()
        let remote = StubEventRemoteDataSource(result: .success([sampleEvent]))
        let repository = DefaultEventRepository(remote: remote, local: local, now: { self.clock.now })
        _ = try await repository.events(forceRefresh: false)

        _ = try await repository.events(forceRefresh: true)

        #expect(remote.fetchCount == 2)
    }

    @Test("A failed sync throws and leaves the stored events untouched")
    func failedSyncKeepsStore() async throws {
        let local = try TestSupport.inMemoryLocal()
        let remote = StubEventRemoteDataSource(result: .success([sampleEvent]))
        let repository = DefaultEventRepository(remote: remote, local: local, now: { self.clock.now })
        let saved = try await repository.events(forceRefresh: false)

        remote.result = .failure(APIError.httpStatus(404))

        await #expect(throws: APIError.httpStatus(404)) {
            try await repository.events(forceRefresh: true)
        }
        #expect(try repository.cachedEvents() == saved)
    }

    @Test("Bookmark calls delegate to the local data source")
    func bookmarksDelegateToLocal() async throws {
        let repository = DefaultEventRepository(
            remote: StubEventRemoteDataSource(result: .success([])),
            local: try TestSupport.inMemoryLocal()
        )

        #expect(try !repository.isBookmarked("1"))
        #expect(try repository.toggleBookmark("1") == true)
        #expect(try repository.isBookmarked("1"))
        #expect(try repository.bookmarkedIDs() == ["1"])
    }
}

// MARK: - Helpers

/// Test double standing in for the network; shared across repository/view-model tests.
@MainActor
final class StubEventRemoteDataSource: EventRemoteDataSource {
    var result: Result<[Event], Error>
    private(set) var fetchCount = 0

    init(result: Result<[Event], Error>) {
        self.result = result
    }

    func fetchEvents() async throws -> [Event] {
        fetchCount += 1
        return try result.get()
    }
}

/// Controllable time source so TTL tests don't have to wait.
@MainActor
private final class Clock {
    var now = Date(timeIntervalSince1970: 1_000_000)
}

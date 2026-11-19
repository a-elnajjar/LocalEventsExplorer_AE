//
//  EventRepositoryTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Tests for DefaultEventRepository (v1: plain remote passthrough, no cache).

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

    @Test("events() returns what the remote data source returns")
    func fetchesFromRemote() async throws {
        let repository = DefaultEventRepository(remote: StubEventRemoteDataSource(result: .success([sampleEvent])))

        let events = try await repository.events()

        #expect(events == [sampleEvent])
    }

    @Test("events() propagates remote errors")
    func propagatesRemoteError() async throws {
        let repository = DefaultEventRepository(
            remote: StubEventRemoteDataSource(result: .failure(APIError.httpStatus(500)))
        )

        await #expect(throws: APIError.httpStatus(500)) {
            try await repository.events()
        }
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

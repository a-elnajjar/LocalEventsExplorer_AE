//
//  EventRemoteDataSourceTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Tests for EventRemoteDataSource.

import Foundation
@testable import LocalEventsExplorer_AE
import Testing

private struct StubWebAPIClient: WebAPIClientService {
    var result: Result<Data, Error>
    func get(_ url: URL) async throws -> Data {
        try result.get()
    }
}

@Suite("EventRemoteDataSource")
@MainActor
struct EventRemoteDataSourceTests {
    private let sampleJSON = Data("""
    {"events":[{"id":"1","title":"T","locationName":"L","latitude":1,"longitude":1,
    "startTime":"2026-12-01T09:00:00Z","imageURL":null}]}
    """.utf8)

    @Test("Success returns decoded events")
    func success() async throws {
        let dataSource = DefaultEventRemoteDataSource(client: StubWebAPIClient(result: .success(sampleJSON)))
        let events = try await dataSource.fetchEvents()
        #expect(events.count == 1)
    }

    @Test("Bad status code propagates as APIError")
    func badStatus() async throws {
        let dataSource = DefaultEventRemoteDataSource(
            client: StubWebAPIClient(result: .failure(APIError.httpStatus(500)))
        )
        await #expect(throws: APIError.httpStatus(500)) {
            try await dataSource.fetchEvents()
        }
    }

    @Test("Invalid JSON maps to APIError.decoding")
    func invalidJSON() async throws {
        let badJSON = Data(#"{"events":[{"id":"1"}]}"#.utf8)
        let dataSource = DefaultEventRemoteDataSource(client: StubWebAPIClient(result: .success(badJSON)))

        await #expect(throws: APIError.self) {
            try await dataSource.fetchEvents()
        }
    }
}

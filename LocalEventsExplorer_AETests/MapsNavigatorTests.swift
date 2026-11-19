//
//  MapsNavigatorTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Tests for the Apple Maps deep link and the detail screen's Directions action (no network).

import Foundation
@testable import LocalEventsExplorer_AE
import Testing

@Suite("Maps directions")
@MainActor
struct MapsNavigatorTests {
    private let event = Event(
        id: "distillery",
        title: "Distillery Winter Village",
        locationName: "55 Mill St, Toronto",
        latitude: 43.6503,
        longitude: -79.3596,
        startTime: Date(timeIntervalSince1970: 0),
        imageURL: nil
    )

    @Test("Directions URL targets Apple Maps with the event's coordinates in driving mode")
    func directionsURL() throws {
        let url = try #require(AppleMapsNavigator.directionsURL(to: event))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })

        #expect(components.host == "maps.apple.com")
        #expect(query["daddr"] == "43.6503,-79.3596")
        #expect(query["dirflg"] == "d")
        #expect(query["q"] == "Distillery Winter Village")
    }

    @Test("Detail view model opens directions to its event")
    func detailOpensDirections() throws {
        let navigator = SpyMapsNavigator()
        let repository = DefaultEventRepository(
            remote: StubEventRemoteDataSource(result: .success([])),
            local: try TestSupport.inMemoryLocal()
        )
        let viewModel = EventDetailViewModel(event: event, repository: repository, mapsNavigator: navigator)

        viewModel.openDirections()

        #expect(navigator.openedEvents == [event])
    }
}

/// Records calls instead of launching Maps, which a unit test can't observe.
@MainActor
private final class SpyMapsNavigator: MapsNavigator {
    private(set) var openedEvents: [Event] = []

    func openDirections(to event: Event) {
        openedEvents.append(event)
    }
}

//
//  LocationViewModelTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Distance and permission handling in the view models.

import CoreLocation
import Foundation
@testable import LocalEventsExplorer_AE
import Testing

@Suite("Location in view models")
@MainActor
struct LocationViewModelTests {
    /// CN Tower, Toronto.
    private let cnTower = CLLocation(latitude: 43.6426, longitude: -79.3871)

    private let event = Event(
        id: "distillery",
        title: "Distillery Winter Village",
        locationName: "55 Mill St, Toronto",
        latitude: 43.6503,
        longitude: -79.3596,
        startTime: Date(timeIntervalSince1970: 0),
        imageURL: nil
    )

    private func makeRepository() throws -> DefaultEventRepository {
        DefaultEventRepository(
            remote: StubEventRemoteDataSource(result: .success([event])),
            local: try TestSupport.inMemoryLocal()
        )
    }

    @Test("With a location, every event gets a distance")
    func distancesWithLocation() async throws {
        let location = StubLocationService(location: cnTower)
        let viewModel = EventListViewModel(repository: try makeRepository(), locationService: location)

        await viewModel.load()

        let events = viewModel.visibleEvents
        #expect(!events.isEmpty)
        #expect(viewModel.userLocation == cnTower)
        #expect(!viewModel.locationDenied)
        for event in events {
            #expect(viewModel.distanceText(for: event) != nil)
        }
    }

    @Test("Permission denied: events still load, no distances, denied flag set")
    func deniedPermission() async throws {
        let location = StubLocationService(authorization: .denied)
        let viewModel = EventListViewModel(repository: try makeRepository(), locationService: location)

        await viewModel.load()

        let event = try #require(viewModel.visibleEvents.first)
        #expect(viewModel.locationDenied)
        #expect(viewModel.distanceText(for: event) == nil)
    }

    @Test("Location is requested once on load, and again on pull-to-refresh")
    func locationRequestedOnce() async throws {
        let location = StubLocationService(location: cnTower)
        let viewModel = EventListViewModel(repository: try makeRepository(), locationService: location)

        await viewModel.load()
        await viewModel.load()
        #expect(location.requestCount == 1)

        await viewModel.refresh()
        #expect(location.requestCount == 2)
    }

    @Test("Detail view model shows the distance from the list's location")
    func detailDistance() throws {
        let repository = try makeRepository()

        let withLocation = EventDetailViewModel(event: event, repository: repository, userLocation: cnTower)
        let withoutLocation = EventDetailViewModel(event: event, repository: repository)

        #expect(withLocation.distanceText == DistanceFormatter.distance(from: cnTower, to: event))
        #expect(withoutLocation.distanceText == nil)
    }
}

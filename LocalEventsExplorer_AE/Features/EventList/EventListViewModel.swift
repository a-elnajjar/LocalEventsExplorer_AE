//
//  EventListViewModel.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Drives the events list: loading, pull-to-refresh, offline fallback, bookmark filter and distance.

import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class EventListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Event])
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Error from the last refresh attempt, shown as a non-blocking banner over loaded content.
    private(set) var refreshError: String?
    private(set) var bookmarkedIDs: Set<String> = []
    var showBookmarkedOnly = false

    private(set) var userLocation: CLLocation?
    private(set) var locationDenied = false

    var visibleEvents: [Event] {
        guard case .loaded(let events) = state else { return [] }
        return showBookmarkedOnly ? events.filter { bookmarkedIDs.contains($0.id) } : events
    }

    private let repository: EventRepository
    private let locationService: LocationService?

    init(repository: EventRepository, locationService: LocationService? = nil) {
        self.repository = repository
        self.locationService = locationService
    }

    func makeDetailViewModel(for event: Event) -> EventDetailViewModel {
        EventDetailViewModel(event: event, repository: repository, userLocation: userLocation)
    }

    func distanceText(for event: Event) -> String? {
        userLocation.map { DistanceFormatter.distance(from: $0, to: event) }
    }

    /// Initial load / re-appear. Uses the repository's TTL cache.
    func load() async {
        guard state != .loading else { return }
        if case .loaded = state {} else {
            state = .loading
        }
        // Events and location load in parallel; the list doesn't wait for GPS.
        async let location: Void = updateLocation(onlyIfMissing: true)
        await fetch(forceRefresh: false)
        await location
    }

    /// Pull-to-refresh: bypasses the TTL cache.
    func refresh() async {
        async let location: Void = updateLocation()
        await fetch(forceRefresh: true)
        await location
    }

    func updateLocation(onlyIfMissing: Bool = false) async {
        guard let locationService else { return }
        if onlyIfMissing, userLocation != nil { return }
        if let location = await locationService.requestCurrentLocation() {
            userLocation = location
        }
        locationDenied = locationService.authorization == .denied
    }

    func reloadBookmarks() {
        bookmarkedIDs = (try? repository.bookmarkedIDs()) ?? []
    }

    private func fetch(forceRefresh: Bool) async {
        defer { reloadBookmarks() }
        do {
            let events = try await repository.events(forceRefresh: forceRefresh)
            state = .loaded(events)
            refreshError = nil
        } catch {
            let message = Self.message(for: error)
            if case .loaded = state {
                // Keep showing what's on screen; surface the error non-destructively.
                refreshError = message
            } else if let stored = try? repository.cachedEvents(), !stored.isEmpty {
                // Offline but we have a previous sync: show it with the banner.
                state = .loaded(stored)
                refreshError = message
            } else {
                state = .failed(message)
            }
        }
    }

    private static func message(for error: Error) -> String {
        (error as? APIError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}

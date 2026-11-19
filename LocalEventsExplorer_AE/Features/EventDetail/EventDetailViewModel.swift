//
//  EventDetailViewModel.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Drives the event detail screen: bookmark state, distance and Maps directions.

import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class EventDetailViewModel {
    let event: Event
    private(set) var isBookmarked = false
    private(set) var errorMessage: String?
    let distanceText: String?

    private let repository: EventRepository
    private let mapsNavigator: MapsNavigator

    init(
        event: Event,
        repository: EventRepository,
        userLocation: CLLocation? = nil,
        mapsNavigator: MapsNavigator? = nil
    ) {
        self.event = event
        self.repository = repository
        self.mapsNavigator = mapsNavigator ?? AppleMapsNavigator()
        distanceText = userLocation.map { DistanceFormatter.distance(from: $0, to: event) }
        isBookmarked = (try? repository.isBookmarked(event.id)) ?? false
    }

    func openDirections() {
        mapsNavigator.openDirections(to: event)
    }

    func toggleBookmark() {
        do {
            isBookmarked = try repository.toggleBookmark(event.id)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't update the bookmark. Please try again."
        }
    }
}

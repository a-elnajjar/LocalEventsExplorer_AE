//
//  CachedEvent.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  SwiftData entities: last-fetched events and user bookmarks.

import Foundation
import SwiftData

@Model
final class CachedEvent {
    @Attribute(.unique) var id: String
    var title: String
    var locationName: String
    var latitude: Double
    var longitude: Double
    var startTime: Date
    var imageURL: URL?
    var fetchedAt: Date

    init(_ event: Event, fetchedAt: Date) {
        id = event.id
        title = event.title
        locationName = event.locationName
        latitude = event.latitude
        longitude = event.longitude
        startTime = event.startTime
        imageURL = event.imageURL
        self.fetchedAt = fetchedAt
    }

    var asEvent: Event {
        Event(
            id: id,
            title: title,
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            startTime: startTime,
            imageURL: imageURL
        )
    }
}

/// Stored separately from `CachedEvent` so bookmarks survive cache refreshes.
@Model
final class Bookmark {
    @Attribute(.unique) var eventID: String
    var createdAt: Date

    init(eventID: String, createdAt: Date = .now) {
        self.eventID = eventID
        self.createdAt = createdAt
    }
}

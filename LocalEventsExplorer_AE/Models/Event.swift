//
//  Event.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Event model.

import Foundation

struct EventsResponse: Decodable {
    let events: [Event]
}

struct Event: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let locationName: String
    let latitude: Double
    let longitude: Double
    let startTime: Date
    let imageURL: URL?
}

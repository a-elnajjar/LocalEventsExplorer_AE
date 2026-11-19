//
//  EventDecoder.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//   Decodes event data

import Foundation

enum EventDecoder {
    static func decode(_ data: Data) throws -> [Event] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(EventsResponse.self, from: data).events
            .sorted { $0.startTime < $1.startTime }
    }
}

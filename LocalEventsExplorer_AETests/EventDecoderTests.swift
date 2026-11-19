//
//  EventDecoderTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Tests for EventDecoder.

import Foundation
@testable import LocalEventsExplorer_AE
import Testing

@Suite("Event JSON decoding")
@MainActor
struct EventDecoderTests {
    @Test("Decodes a valid events payload, sorted by start time")
    func decodesValidPayload() throws {
        let json = Data("""
        {
          "events": [
            {
              "id": "evt-2",
              "title": "Night Market",
              "locationName": "Harbor Square",
              "latitude": 40.7128,
              "longitude": -74.0060,
              "startTime": "2026-12-05T19:00:00Z",
              "imageURL": "https://example.com/night-market.jpg"
            },
            {
              "id": "evt-1",
              "title": "Farmers Market",
              "locationName": "Main Street",
              "latitude": 40.7357,
              "longitude": -74.1724,
              "startTime": "2026-12-01T09:00:00Z",
              "imageURL": null
            }
          ]
        }
        """.utf8)

        let events = try EventDecoder.decode(json)

        #expect(events.count == 2)
        #expect(events.map(\.id) == ["evt-1", "evt-2"], "must be sorted by startTime ascending")
        #expect(events[0].imageURL == nil)
        #expect(events[1].imageURL == URL(string: "https://example.com/night-market.jpg"))
    }

    @Test("Throws on malformed JSON")
    func throwsOnInvalidPayload() {
        let bad = Data("{ not valid json".utf8)
        #expect(throws: (any Error).self) {
            try EventDecoder.decode(bad)
        }
    }
}

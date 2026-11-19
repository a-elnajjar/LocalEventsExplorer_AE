//
//  DistanceFormatterTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Tests for distance calculation and formatting (no network, no location permission).

import CoreLocation
import Foundation
@testable import LocalEventsExplorer_AE
import Testing

@Suite("DistanceFormatter")
@MainActor
struct DistanceFormatterTests {
    private let metric = Locale(identifier: "en_CA")
    private let imperial = Locale(identifier: "en_US")

    /// CN Tower, Toronto.
    private let user = CLLocation(latitude: 43.6426, longitude: -79.3871)

    @Test("Distance to the Distillery District is about 2.4 km")
    func knownDistance() {
        let distillery = makeEvent(latitude: 43.6503, longitude: -79.3596)

        let meters = DistanceFormatter.meters(from: user, to: distillery)

        #expect((2_300...2_450).contains(meters))
        #expect(DistanceFormatter.distance(from: user, to: distillery, locale: metric) == "2.4 km")
    }

    @Test("Metric: under 1 km shows meters", arguments: [
        (CLLocationDistance(0), "0 m"),
        (847, "847 m"),
        (994, "994 m")
    ])
    func metricMeters(meters: CLLocationDistance, expected: String) {
        #expect(DistanceFormatter.format(meters: meters, locale: metric) == expected)
    }

    @Test("Metric: 1 km and over shows km with one decimal", arguments: [
        (CLLocationDistance(1_000), "1 km"),
        (2_340, "2.3 km"),
        (15_000, "15 km")
    ])
    func metricKilometers(meters: CLLocationDistance, expected: String) {
        #expect(DistanceFormatter.format(meters: meters, locale: metric) == expected)
    }

    @Test("US locale shows miles")
    func imperialMiles() {
        #expect(DistanceFormatter.format(meters: 2_253, locale: imperial) == "1.4 mi")
    }

    private func makeEvent(latitude: Double, longitude: Double) -> Event {
        Event(
            id: "e",
            title: "Event",
            locationName: "Toronto",
            latitude: latitude,
            longitude: longitude,
            startTime: Date(timeIntervalSince1970: 0),
            imageURL: nil
        )
    }
}

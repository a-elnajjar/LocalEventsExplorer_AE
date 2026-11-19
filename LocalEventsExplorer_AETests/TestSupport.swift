//
//  TestSupport.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Shared test helpers.

import CoreLocation
import Foundation
@testable import LocalEventsExplorer_AE
import SwiftData

@MainActor
enum TestSupport {
    /// Fresh, empty SwiftData store kept in memory (owns its container).
    static func inMemoryLocal() throws -> SwiftDataEventLocalDataSource {
        SwiftDataEventLocalDataSource(container: try .app(inMemory: true))
    }
}

/// Stand-in for Core Location: returns a fixed location and permission state.
/// Needed because real location permission can't be granted or denied from a unit test.
@MainActor
final class StubLocationService: LocationService {
    var authorization: LocationAuthorization
    var location: CLLocation?
    private(set) var requestCount = 0

    init(authorization: LocationAuthorization = .authorized, location: CLLocation? = nil) {
        self.authorization = authorization
        self.location = location
    }

    func requestCurrentLocation() async -> CLLocation? {
        requestCount += 1
        return authorization == .authorized ? location : nil
    }
}

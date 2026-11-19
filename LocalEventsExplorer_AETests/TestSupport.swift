//
//  TestSupport.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Shared test helpers.

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

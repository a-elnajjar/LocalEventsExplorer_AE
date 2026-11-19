//
//  AppConfig.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  App-wide settings such as the events URL and cache TTL.

import Foundation

enum AppConfig {
    /// Mock REST endpoint: a static JSON file hosted on GitHub.
    static let eventsURL: URL = {
        let raw = "https://raw.githubusercontent.com/a-elnajjar/LocalEventsExplorerJSON-/main/events.json"
        guard let url = URL(string: raw) else {
            preconditionFailure("Invalid eventsURL constant: \(raw)")
        }
        return url
    }()

    /// Cache time-to-live in seconds.
    static let cacheTTL: TimeInterval = 15 * 60

    /// How long a single network request waits before timing out.
    static let requestTimeout: TimeInterval = 15

    /// Subsystem for os.Logger instances across the app, so log output is grouped consistently.
    static let loggerSubsystem = "LocalEventsExplorer_AE"
}

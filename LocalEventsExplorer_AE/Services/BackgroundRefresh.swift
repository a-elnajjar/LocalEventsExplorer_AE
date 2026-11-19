//
//  BackgroundRefresh.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Low-frequency background sync of events via BGAppRefreshTask.
//  iOS decides the exact time based on battery, network and how often the app is used.

import BackgroundTasks
import os

enum BackgroundRefresh {
    private static let logger = Logger(subsystem: AppConfig.loggerSubsystem, category: "BackgroundRefresh")

    /// Schedules the next background refresh.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: AppConfig.backgroundRefreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: AppConfig.backgroundRefreshInterval)
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Scheduled background refresh")
        } catch {
            // Likely simulator or disabled.
            logger.error("Could not schedule background refresh: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Performs the refresh.
    @MainActor
    static func run(repository: EventRepository) async {
        schedule()
        do {
            let events = try await repository.events(forceRefresh: true)
            logger.info("Background refresh saved \(events.count) events")
        } catch {
            logger.error("Background refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

//
//  EventRepository.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Single source of truth for events (v1: passes through to the remote API).

import Foundation

@MainActor
protocol EventRepository {
    func events() async throws -> [Event]
}

@MainActor
final class DefaultEventRepository: EventRepository {
    private let remote: EventRemoteDataSource

    init(remote: EventRemoteDataSource = DefaultEventRemoteDataSource()) {
        self.remote = remote
    }

    func events() async throws -> [Event] {
        try await remote.fetchEvents()
    }
}

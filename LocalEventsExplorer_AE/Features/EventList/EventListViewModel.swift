//
//  EventListViewModel.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  View model for events list.

import Foundation
import Observation

@MainActor
@Observable
final class EventListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Event])
        case failed(String)
    }

    private(set) var state: State = .idle
    /// Error from the last refresh attempt, shown as a non-blocking banner over loaded content.
    private(set) var refreshError: String?

    private let repository: EventRepository

    init(repository: EventRepository) {
        self.repository = repository
    }



    func load() async {
        guard state != .loading else { return }
        if case .loaded = state {} else {
            state = .loading
        }
        await fetch()
    }

    func refresh() async {
        await fetch()
    }

    private func fetch() async {
        do {
            state = .loaded(try await repository.events())
            refreshError = nil
        } catch {
            let message = Self.message(for: error)
            if case .loaded = state {
                // Show error without changing state.
                refreshError = message
            } else {
                state = .failed(message)
            }
        }
    }

    private static func message(for error: Error) -> String {
        (error as? APIError)?.errorDescription ?? "Something went wrong. Please try again."
    }
}

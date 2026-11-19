//
//  EventDetailViewModel.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Drives the event detail screen: bookmark state and toggling.

import Foundation
import Observation

@MainActor
@Observable
final class EventDetailViewModel {
    let event: Event
    private(set) var isBookmarked = false
    private(set) var errorMessage: String?

    private let repository: EventRepository

    init(event: Event, repository: EventRepository) {
        self.event = event
        self.repository = repository
        isBookmarked = (try? repository.isBookmarked(event.id)) ?? false
    }

    func toggleBookmark() {
        do {
            isBookmarked = try repository.toggleBookmark(event.id)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't update the bookmark. Please try again."
        }
    }
}

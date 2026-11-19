//
//  EventDetailViewModel.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  View model for event detail screen.

import Foundation
import Observation

@MainActor
@Observable
final class EventDetailViewModel {
    let event: Event

    init(event: Event) {
        self.event = event
    }
}

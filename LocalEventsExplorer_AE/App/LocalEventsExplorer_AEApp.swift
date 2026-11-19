//
//  LocalEventsExplorer_AEApp.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  App entry point.

import SwiftUI

@main
struct LocalEventsExplorerApp: App {
    private let repository: EventRepository = DefaultEventRepository()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                EventListView(viewModel: EventListViewModel(repository: repository))
            }
        }
    }
}

//
//  LocalEventsExplorer_AEApp.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  App entry point: composition root, dependencies created once here.

import SwiftData
import SwiftUI

@main
struct LocalEventsExplorerApp: App {
    private let modelContainer: ModelContainer
    private let repository: EventRepository
    private let locationService: LocationService

    init() {
        do {
            modelContainer = try .app()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        repository = DefaultEventRepository(
            remote: DefaultEventRemoteDataSource(),
            local: SwiftDataEventLocalDataSource(context: modelContainer.mainContext)
        )
        locationService = CoreLocationService()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                EventListView(viewModel: EventListViewModel(repository: repository, locationService: locationService))
            }
        }
        .modelContainer(modelContainer)
    }
}

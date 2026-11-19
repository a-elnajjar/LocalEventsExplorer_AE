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

    @Environment(\.scenePhase) private var scenePhase

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
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                BackgroundRefresh.schedule()
            }
        }
        .backgroundTask(.appRefresh(AppConfig.backgroundRefreshTaskIdentifier)) { [repository] in
            await BackgroundRefresh.run(repository: repository)
        }
    }
}

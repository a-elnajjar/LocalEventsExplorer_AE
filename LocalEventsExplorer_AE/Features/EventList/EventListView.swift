//
//  EventListView.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Events list: spinner, list with pull-to-refresh, error screen, offline banner, bookmark filter.

import SwiftUI

struct EventListView: View {
    @State private var viewModel: EventListViewModel

    init(viewModel: EventListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Events")
            .navigationDestination(for: Event.self) { event in
                EventDetailView(viewModel: viewModel.makeDetailViewModel(for: event))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle(isOn: $viewModel.showBookmarkedOnly) {
                        Image(systemName: viewModel.showBookmarkedOnly ? "bookmark.fill" : "bookmark")
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel("Show bookmarked only")
                }
            }
            .task { await viewModel.load() }
            .onAppear { viewModel.reloadBookmarks() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading events…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            let events = viewModel.visibleEvents
            List {
                if let error = viewModel.refreshError {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                ForEach(events) { event in
                    NavigationLink(value: event) {
                        EventRow(event: event, isBookmarked: viewModel.bookmarkedIDs.contains(event.id))
                    }
                }
            }
            .refreshable { await viewModel.refresh() }
            .overlay {
                if events.isEmpty {
                    if viewModel.showBookmarkedOnly {
                        ContentUnavailableView(
                            "No bookmarks yet",
                            systemImage: "bookmark",
                            description: Text("Open an event and tap the bookmark icon to save it.")
                        )
                    } else {
                        ContentUnavailableView("No events nearby", systemImage: "calendar")
                    }
                }
            }

        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load events", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct EventRow: View {
    let event: Event
    var isBookmarked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(event.title)
                    .font(.headline)
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(.tint)
                        .accessibilityLabel("Bookmarked")
                }
            }
            Text(event.locationName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(event.startTime, format: .dateTime.weekday().month().day().hour().minute())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        let repository = DefaultEventRepository(local: SwiftDataEventLocalDataSource.preview)
        EventListView(viewModel: EventListViewModel(repository: repository))
    }
}

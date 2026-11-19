//
//  EventListView.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Event list screen with pull-to-refresh and error states.

import SwiftUI

struct EventListView: View {
    @State private var viewModel: EventListViewModel

    init(viewModel: EventListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        content
            .navigationTitle("Events")
            .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading events…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let events):
            List {
                if let error = viewModel.refreshError {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                ForEach(events) { event in
                    NavigationLink {
                        EventDetailView(viewModel: EventDetailViewModel(event: event))
                    } label: {
                        EventRow(event: event)
                    }
                }
            }
            .refreshable { await viewModel.refresh() }
            .overlay {
                if events.isEmpty {
                    ContentUnavailableView("No events nearby", systemImage: "calendar")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
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
        EventListView(viewModel: EventListViewModel(repository: DefaultEventRepository()))
    }
}

//
//  EventDetailView.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Event detail screen.

import SwiftUI

struct EventDetailView: View {
    @State private var viewModel: EventDetailViewModel

    init(viewModel: EventDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var event: Event { viewModel.event }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let imageURL = event.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                                .clipped()
                        } else if phase.error != nil {
                            imagePlaceholder
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 240)
                        }
                    }
                } else {
                    imagePlaceholder
                }

                Text(event.title)
                    .font(.title.bold())

                Label {
                    Text(event.startTime, format: .dateTime.weekday(.wide).month().day().hour().minute())
                } icon: {
                    Image(systemName: "calendar")
                }

                Label(event.locationName, systemImage: "mappin.and.ellipse")
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var imagePlaceholder: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: 240)
            .background(.quaternary)
    }
}

#Preview {
    NavigationStack {
        EventDetailView(
            viewModel: EventDetailViewModel(
                event: Event(
                    id: "1", title: "Sample Event", locationName: "Toronto",
                    latitude: 43.65, longitude: -79.38,
                    startTime: .now, imageURL: nil
                )
            )
        )
    }
}

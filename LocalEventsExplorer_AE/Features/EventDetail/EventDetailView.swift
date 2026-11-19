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
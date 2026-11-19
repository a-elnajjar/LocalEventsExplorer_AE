# LocalEventsExplorer

A SwiftUI iOS app for discovering local events. Browse events, view event details, save bookmarks, see how far away each event is, and get directions in Apple Maps. It keeps working offline.

Built for the Mobile Developer technical assessment (Assignment 1: Local Events Explorer).

- **Demo video:** [VideoDemo/](VideoDemo/) (under 3 minutes)
- **Architecture and sequence diagrams:** [docs/architecture.md](docs/architecture.md)

## Features

| Requirement | How it's done |
|---|---|
| Mock REST API | Static JSON file self-hosted in this repo at [MockAPI/events.json](MockAPI/events.json), served via GitHub raw (`AppConfig.eventsURL`) |
| Local DB | SwiftData stores the last-fetched events and bookmarks |
| API cache with TTL | Events are served from SwiftData for 15 minutes, then refetched. Pull to refresh skips the cache. |
| Image caching | Decoded images in memory (`NSCache`, 100 images) and downloaded data on disk (`URLCache`, 100 MB) |
| Location + distance | One-shot location request, distance shown in the list and on the detail screen |
| Maps deep link | Opens Apple Maps with driving directions to the event |
| Background refresh | `BGAppRefreshTask`, earliest every hour. iOS decides when it actually runs. |
| Network failures | If a refresh fails, the app keeps showing saved events with an offline banner |
| Standards | MVVM, dependency injection, SwiftLint, 32 unit tests |

## Requirements

- Xcode with the iOS 26.2 SDK or later
- An iOS 26.2+ simulator or device
- Optional: [SwiftLint](https://github.com/realm/SwiftLint) (`brew install swiftlint`). The build shows a warning if it isn't installed.

No API keys or third-party packages are needed.

## Run the app

1. Clone the repo and open `LocalEventsExplorer_AE.xcodeproj` in Xcode.
2. Select the `LocalEventsExplorer_AE` scheme and an iOS 26.2+ simulator or device.
3. Press **⌘R**.
4. Allow location access when asked, to see distances. In the simulator, set a location under **Features → Location**.

To use a different endpoint, change `eventsURL` in `LocalEventsExplorer_AE/App/AppConfig.swift`.

**To try offline mode:** run the app once online, then turn off the network (on a Mac, turn off Wi-Fi) and pull to refresh. The saved events stay on screen with an offline banner.

**To try background refresh in the simulator:** pause the debugger after the app goes to the background and run:

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"ae.LocalEventsExplorer-AE.refresh"]
```

## Run tests

In Xcode, press **⌘U**, or from the command line:

```sh
xcodebuild test \
  -project LocalEventsExplorer_AE.xcodeproj \
  -scheme LocalEventsExplorer_AE \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Replace `iPhone 17` with any iOS 26.2+ simulator you have installed.

The tests use Swift Testing and cover:

- **Repository:** first launch fetches and saves, cache is used within the TTL, refetch after the TTL, pull to refresh skips the cache, a failed sync keeps the saved events
- **Local storage:** save and load, save replaces old events, bookmarks survive a refresh
- **Remote data source and errors:** success, bad HTTP status, invalid JSON, timeout and no-connection messages
- **Decoding:** valid and invalid payloads
- **View models:** bookmark toggle and filter, distances, denied location permission
- **Services:** distance formatting (metric and imperial) and the Maps directions URL

## Linting

The project runs SwiftLint as a build phase using `.swiftlint.yml`. To run it by hand:

```sh
swiftlint lint
```

## Architecture

MVVM with an offline-first repository. Views only talk to view models, and view models only talk to the repository and services through protocols. All dependencies are created once in `LocalEventsExplorer_AEApp` (the composition root) and passed in through initializers, so tests can swap in fakes.

```
LocalEventsExplorer_AE/
├── App/        App entry point (composition root) and AppConfig
├── Models/     Event and EventDecoder
├── Data/       API client, remote data source, repository, SwiftData storage
├── Features/   EventList, EventDetail and shared views (each a View + ViewModel)
└── Services/   Location, distance, Maps, image loading, background refresh
```

**How loading works:** the list view model asks the repository for events. If the last fetch is under 15 minutes old, the repository returns the saved events from SwiftData. Otherwise it fetches from the API, replaces the saved events and returns them. If the fetch fails, the view model shows the saved events with an offline banner, or an error screen if nothing is saved yet.

See [docs/architecture.md](docs/architecture.md) for the full architecture diagram and the end-to-end sequence diagram.

## Trade-offs

- **SwiftData over Core Data:** less code and fits SwiftUI naturally, but it needs a newer iOS version.
- **15-minute TTL:** events don't change often, so this saves network and battery. The cost is that data can be up to 15 minutes old, and pull to refresh covers that.
- **Replace all saved events on refresh:** simple and always matches the server. Bookmarks are stored in their own table by event ID, so they survive a refresh.
- **Image cache without a library:** `NSCache` + `URLCache` covers what the app needs and avoids a dependency. `NSCache` also frees memory on its own under memory pressure.
- **Low-frequency background refresh:** at most about once an hour, to save battery. iOS decides the exact timing, so it can't be relied on for fresh data.
- **Offline fallback in the view model:** keeps the repository simple, but background refresh doesn't use the fallback (it just logs the error).
- **Bookmark read errors are ignored:** if loading bookmarks fails, the list shows none instead of blocking the screen. A local read failing is rare. In production I'd log it.
- **Static JSON in this repo as the mock API:** free, reliable, and versioned with the app (`MockAPI/events.json`), but GitHub caches raw files for a few minutes, so changes to the JSON don't show up right away.
- **iOS 26.2 minimum:** lets me use the latest SwiftUI and SwiftData APIs, but limits which devices can run it.

## What I'd do next

- Tests for the list view model's offline banner and saved-events fallback
- Move the offline fallback into the repository so every caller gets it
- Log errors (including bookmark read errors) with `OSLog`
- Update saved events by ID instead of replacing them all
- Lower the minimum iOS version if needed
- UI tests for the main flow, and CI (GitHub Actions) for build, lint and tests
- Accessibility pass (VoiceOver labels, Dynamic Type)

## Time spent

The final version took about 4 hours of coding (see the commit history), plus time for the docs and demo video. In total I spent about **[X] hours**, including two earlier attempts that helped me settle the design.

## Use of AI

I used AI tools to speed up boilerplate and documentation. I designed the architecture, reviewed every line, and wrote and checked the tests myself.
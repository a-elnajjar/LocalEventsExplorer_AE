# LocalEventsExplorer

A SwiftUI iOS app for discovering local events. Browse events, view event details, save bookmarks, and get directions in Apple Maps.

## Features

- Loads event data from a static JSON endpoint configured in `AppConfig`.
- Caches events locally with SwiftData and refreshes the cache after 15 minutes.
- Shows cached events when a network refresh fails.
- Saves bookmarks locally and filters the list to bookmarked events.
- Shows distance to events when location access is available.
- Loads and caches event images in memory and on disk.
- Opens event directions in Apple Maps.
- Schedules low-frequency background event refreshes; iOS determines when these tasks run.

## Requirements

- Xcode with the iOS 26.2 SDK or later.
- An iOS 26.2 or later simulator or device.

The project currently sets its iOS deployment target to 26.2. No API keys or additional package installation are required.

## Run the app

1. Open `LocalEventsExplorer_AE.xcodeproj` in Xcode.
2. Select the `LocalEventsExplorer_AE` scheme and an available iOS 26.2+ simulator or device.
3. Build and run the app.

Events are fetched from the URL in `LocalEventsExplorer_AE/App/AppConfig.swift`. Update that setting to use a different JSON endpoint.

## Run tests

Run the `LocalEventsExplorer_AE` scheme's test action in Xcode, or use the command line:

```sh
xcodebuild test \
  -project LocalEventsExplorer_AE.xcodeproj \
  -scheme LocalEventsExplorer_AE \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Replace `iPhone 17` with the name of an iOS 26.2+ simulator installed on your machine, if needed.

## Linting

The repository includes `.swiftlint.yml`. If SwiftLint is installed, run:

```sh
swiftlint lint
```

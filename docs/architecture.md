# LocalEventsExplorer_AE - App Architecture

LocalEventsExplorer_AE is a SwiftUI iOS app that shows nearby events from a remote JSON feed, with an offline-first SwiftData cache, bookmarks, location-based distances, and background refresh.

## All-App Architecture Diagram

A single end-to-end view of every component: app entry, SwiftUI views, view models, domain models, data layer, persistence, device services, iOS frameworks, and external services. Solid arrows are runtime call/data flow; dotted arrows are configuration or cross-cutting influence.

<!-- mermaid-checked: no \n, no em-dash/en-dash, no {} in labels, subgraphs are id["label"], arrows are -->|"label"|, all subgraphs closed by end, ids unique -->
```mermaid
flowchart TD
    subgraph fApp["App Entry - Composition Root"]
        fMain["LocalEventsExplorerApp"]
        fConfig["AppConfig"]
    end
    subgraph fUI["Presentation - SwiftUI"]
        fListView["EventListView"]
        fDetailView["EventDetailView"]
        fAsyncImg["CachedAsyncImage"]
    end
    subgraph fVM["View Models - Observation"]
        fListVM["EventListViewModel"]
        fDetailVM["EventDetailViewModel"]
    end
    subgraph fDomain["Domain Models"]
        fEvent["Event"]
        fDecoder["EventDecoder"]
        fAPIErr["APIError"]
    end
    subgraph fData["Data Layer - offline-first"]
        fRepo["DefaultEventRepository - 15 min TTL"]
        fRemote["DefaultEventRemoteDataSource"]
        fLocal["SwiftDataEventLocalDataSource"]
        fClient["URLSessionAPIClient"]
    end
    subgraph fPersist["Persistence - SwiftData"]
        fStore[("ModelContainer: CachedEvent, Bookmark")]
    end
    subgraph fSvc["Device Services"]
        fLoc["CoreLocationService"]
        fMaps["AppleMapsNavigator"]
        fBG["BackgroundRefresh"]
        fImg["ImageLoader - NSCache + URLCache"]
        fDist["DistanceFormatter"]
    end
    subgraph fOS["iOS Frameworks"]
        fCL["CoreLocation"]
        fBGT["BGTaskScheduler"]
        fUIApp["UIApplication"]
    end
    subgraph fExt["External"]
        fFeed["Events JSON feed - GitHub raw"]
        fAppleMaps["Apple Maps app"]
        fHosts["Image hosts"]
    end

    fMain -->|"creates once"| fRepo
    fMain -->|"creates"| fListVM
    fMain -->|"creates"| fLoc
    fMain -->|"owns"| fStore
    fMain -.->|"on background: schedule"| fBG
    fConfig -.->|"URL, TTL, timeouts, limits"| fRepo
    fConfig -.->|"timeout"| fClient
    fConfig -.->|"cache limits"| fImg

    fListView -->|"binds"| fListVM
    fListView -->|"navigates"| fDetailView
    fDetailView -->|"binds"| fDetailVM
    fListView -->|"thumbnails"| fAsyncImg
    fDetailView -->|"hero image"| fAsyncImg
    fAsyncImg -->|"image for url"| fImg

    fListVM -->|"makeDetailViewModel"| fDetailVM
    fListVM -->|"events, bookmarks"| fRepo
    fListVM -->|"one-shot location"| fLoc
    fListVM -->|"distance text"| fDist
    fDetailVM -->|"toggle bookmark"| fRepo
    fDetailVM -->|"open directions"| fMaps
    fDetailVM -->|"distance text"| fDist

    fRepo -->|"fetch on stale or forced"| fRemote
    fRepo -->|"load, save, bookmarks"| fLocal
    fRemote -->|"GET"| fClient
    fRemote -->|"decode"| fDecoder
    fDecoder -->|"produces"| fEvent
    fClient -.->|"maps failures to"| fAPIErr
    fLocal -->|"ModelContext CRUD"| fStore
    fBG -.->|"forceRefresh"| fRepo

    fLoc -->|"delegate callbacks"| fCL
    fBG -->|"submit task request"| fBGT
    fMaps -->|"open url"| fUIApp
    fClient -->|"HTTPS GET"| fFeed
    fUIApp -->|"deep link"| fAppleMaps
    fImg -->|"HTTPS"| fHosts
```

### Technology Stack Summary

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| Presentation | SwiftUI | iOS 17+ | Declarative UI, NavigationStack, pull-to-refresh |
| State | Observation (`@Observable`) | iOS 17+ | View model state driving the views |
| Data access | SwiftData (`@Model`, `ModelContext`) | iOS 17+ | Offline cache (`CachedEvent`) and bookmarks (`Bookmark`) |
| Networking | URLSession (async/await) | Foundation | JSON GET with timeout and `APIError` mapping |
| Location | CoreLocation | - | One-shot "When In Use" location for distances |
| Background | BackgroundTasks (`BGAppRefreshTask`) | - | Periodic event sync while backgrounded |
| Images | NSCache + URLCache | - | Two-level (memory + disk) image caching |
| Logging | os.Logger | - | Structured logs under subsystem `LocalEventsExplorer_AE` |
| Tests | Swift Testing (`@Test`) | - | 32 unit tests for repository, data sources, view models, formatters |

### Key Architectural Decisions

- **Offline-first repository with TTL**: `DefaultEventRepository` serves SwiftData-cached events when fresh (< 15 min), otherwise fetches remotely, persists, and re-reads from the cache - the local store is the single source of truth.
- **Protocol-based dependency injection from a composition root**: all dependencies (`EventRepository`, `EventRemoteDataSource`, `EventLocalDataSource`, `WebAPIClientService`, `LocationService`, `MapsNavigator`, `ImageLoading`) are protocols wired once in `LocalEventsExplorerApp.init`, enabling the test doubles in `LocalEventsExplorer_AETests`.
- **Graceful degradation on failure**: refresh errors on a loaded list surface as a non-blocking banner; when offline with a prior sync, the cached list is shown with the banner instead of a failure screen.

## All-App Sequence Diagram

One end-to-end trace of the entire app lifecycle: launch, offline-first event loading, detail with bookmark and directions, and background refresh.

<!-- mermaid-checked: no \n, no em-dash/en-dash, no {} in labels, participants are plain ids, all alt/par/opt/rect blocks closed by end -->
```mermaid
sequenceDiagram
    autonumber
    actor User
    participant App as LocalEventsExplorerApp
    participant List as EventListView
    participant LVM as EventListViewModel
    participant Loc as CoreLocationService
    participant Repo as DefaultEventRepository
    participant Local as SwiftDataEventLocalDataSource
    participant Remote as DefaultEventRemoteDataSource
    participant API as URLSessionAPIClient
    participant Feed as Events JSON (GitHub raw)
    participant Img as ImageLoader
    participant Detail as EventDetailView
    participant DVM as EventDetailViewModel
    participant Maps as AppleMapsNavigator
    participant iOS as iOS (UIApplication / BGTaskScheduler)

    rect rgb(235, 243, 255)
    Note over App: App launch - composition root
    User->>App: launch app
    App->>App: create ModelContainer, Repository, LocationService
    App->>List: show EventListView(viewModel:)
    end

    rect rgb(235, 255, 238)
    Note over List,Feed: Load events - offline-first with TTL
    List->>LVM: .task load()
    par location in parallel
        LVM->>Loc: requestCurrentLocation()
        Loc-->>LVM: CLLocation or nil
    and events
        LVM->>Repo: events(forceRefresh: false)
        Repo->>Local: lastFetchDate()
        alt cache fresh (< 15 min)
            Repo->>Local: loadEvents()
            Local-->>Repo: cached [Event]
        else stale or empty
            Repo->>Remote: fetchEvents()
            Remote->>API: get(eventsURL)
            API->>Feed: HTTPS GET
            Feed-->>API: 200 + JSON
            API-->>Remote: Data
            Remote-->>Repo: decoded [Event]
            Repo->>Local: save(events, fetchedAt: now)
            Repo->>Local: loadEvents()
            Local-->>Repo: [Event] sorted by startTime
        end
        Repo-->>LVM: [Event]
    end
    LVM->>Repo: bookmarkedIDs()
    Repo-->>LVM: Set of IDs
    LVM-->>List: state = .loaded, distances shown
    List->>Img: thumbnails via CachedAsyncImage
    opt fetch failed
        alt cached events exist
            LVM-->>List: show cache + refreshError banner
        else nothing cached
            LVM-->>List: state = .failed(message)
        end
    end
    end

    rect rgb(255, 248, 235)
    Note over User,iOS: Detail - bookmark and directions
    User->>List: tap event row
    List->>LVM: makeDetailViewModel(for: event)
    LVM->>DVM: init(event, repository, userLocation)
    DVM->>Repo: isBookmarked(event.id)
    Repo-->>DVM: Bool
    List->>Detail: push EventDetailView
    Detail->>Img: hero image via CachedAsyncImage
    User->>Detail: tap bookmark
    Detail->>DVM: toggleBookmark()
    DVM->>Repo: toggleBookmark(event.id)
    Repo->>Local: insert or delete Bookmark, save()
    Local-->>DVM: new bookmark state
    User->>Detail: tap Get Directions
    Detail->>DVM: openDirections()
    DVM->>Maps: openDirections(to: event)
    Maps->>iOS: open maps.apple.com deep link
    iOS-->>User: Apple Maps with driving directions
    end

    rect rgb(245, 238, 255)
    Note over App,Feed: Background refresh
    User->>iOS: send app to background
    iOS->>App: scenePhase = .background
    App->>iOS: BackgroundRefresh.schedule() (earliest +1h)
    Note over iOS: iOS picks the actual run time
    iOS->>App: wake for appRefresh task
    App->>Repo: BackgroundRefresh.run - events(forceRefresh: true)
    Repo->>Feed: fetch + persist to SwiftData
    Repo-->>App: synced (or error, logged)
    end
```

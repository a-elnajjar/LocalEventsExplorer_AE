//
//  BookmarkViewModelTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Bookmark behaviour in the detail and list view models.

import Foundation
@testable import LocalEventsExplorer_AE
import Testing

@Suite("Bookmarks in view models")
@MainActor
struct BookmarkViewModelTests {
    private let event = Event(
        id: "evt-1", title: "Test Event", locationName: "Toronto",
        latitude: 43.65, longitude: -79.38,
        startTime: Date(timeIntervalSince1970: 1_000), imageURL: nil
    )

    private func makeRepository() throws -> DefaultEventRepository {
        DefaultEventRepository(
            remote: StubEventRemoteDataSource(result: .success([event])),
            local: try TestSupport.inMemoryLocal()
        )
    }

    @Test("Detail view model toggles and persists the bookmark")
    func detailTogglesBookmark() throws {
        let repository = try makeRepository()
        let viewModel = EventDetailViewModel(event: event, repository: repository)
        #expect(!viewModel.isBookmarked)

        viewModel.toggleBookmark()
        #expect(viewModel.isBookmarked)

        // A fresh view model reads the same persisted state.
        #expect(EventDetailViewModel(event: event, repository: repository).isBookmarked)

        viewModel.toggleBookmark()
        #expect(!viewModel.isBookmarked)
    }

    @Test("List filter shows only bookmarked events")
    func listFiltersBookmarked() async throws {
        let repository = try makeRepository()
        let viewModel = EventListViewModel(repository: repository)
        await viewModel.load()
        let all = viewModel.visibleEvents
        let bookmarked = try #require(all.first)

        try repository.toggleBookmark(bookmarked.id)
        viewModel.reloadBookmarks()
        viewModel.showBookmarkedOnly = true

        #expect(viewModel.visibleEvents == [bookmarked])
        #expect(viewModel.bookmarkedIDs == [bookmarked.id])

        viewModel.showBookmarkedOnly = false
        #expect(viewModel.visibleEvents == all)
    }

    @Test("Bookmarks survive a forced refresh")
    func bookmarksSurviveRefresh() async throws {
        let repository = try makeRepository()
        let viewModel = EventListViewModel(repository: repository)
        await viewModel.load()
        let id = try #require(viewModel.visibleEvents.first?.id)
        try repository.toggleBookmark(id)

        await viewModel.refresh()

        #expect(viewModel.bookmarkedIDs.contains(id))
    }
}

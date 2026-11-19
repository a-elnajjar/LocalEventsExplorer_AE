//
//  EventRemoteDataSource.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Remote data source for events.

import Foundation

protocol EventRemoteDataSource: Sendable {
    func fetchEvents() async throws -> [Event]
}

struct DefaultEventRemoteDataSource: EventRemoteDataSource {
    private let client: WebAPIClientService
    private let url: URL

    init(client: WebAPIClientService = URLSessionAPIClient(), url: URL = AppConfig.eventsURL) {
        self.client = client
        self.url = url
    }

    func fetchEvents() async throws -> [Event] {
        let data = try await client.get(url)
        do {
            return try EventDecoder.decode(data)
        } catch let error as DecodingError {
            throw APIError(error)
        }
    }
}

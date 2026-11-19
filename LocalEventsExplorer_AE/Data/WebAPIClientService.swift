//
//  WebAPIClientService.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  HTTP client that maps network failures to APIError.

import Foundation
import os

protocol WebAPIClientService: Sendable {
    func get(_ url: URL) async throws -> Data
}

final class URLSessionAPIClient: WebAPIClientService {
    private let session: URLSession
    private let timeout: TimeInterval

    init(session: URLSession = .shared, timeout: TimeInterval = 15) {
        self.session = session
        self.timeout = timeout
    }

    private static let logger = Logger(subsystem: "LocalEventsExplorer", category: "APIClient")

    func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            Self.logger.error("GET \(url.absoluteString, privacy: .public) failed: \(error.code.rawValue)")
            throw APIError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            Self.logger.error("GET \(url.absoluteString, privacy: .public) returned HTTP \(http.statusCode)")
            throw APIError.httpStatus(http.statusCode)
        }
        return data
    }
}

// MARK: - APIError

enum APIError: Error, Equatable {
    case offline
    case timeout
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
    case transport(URLError.Code)

    init(_ error: URLError) {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            self = .offline
        case .timedOut:
            self = .timeout
        default:
            self = .transport(error.code)
        }
    }

    init(_ error: DecodingError) {
        let detail: String
        switch error {
        case .keyNotFound(let key, let context):
            detail = "Missing key '\(key.stringValue)' at \(Self.path(context))"
        case .typeMismatch(let type, let context):
            detail = "Type mismatch for \(type) at \(Self.path(context))"
        case .valueNotFound(let type, let context):
            detail = "Null value for \(type) at \(Self.path(context))"
        case .dataCorrupted(let context):
            detail = "Corrupted data at \(Self.path(context)): \(context.debugDescription)"
        @unknown default:
            detail = String(describing: error)
        }
        self = .decoding(detail)
    }

    private static func path(_ context: DecodingError.Context) -> String {
        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
        return path.isEmpty ? "root" : path
    }
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .offline:
            return "You're offline. Check your connection and try again."
        case .timeout:
            return "The request timed out. Please try again."
        case .invalidResponse, .transport:
            return "Couldn't reach the server. Please try again."
        case .httpStatus(let code) where (500..<600).contains(code):
            return "The server is having problems (\(code)). Please try again later."
        case .httpStatus(let code):
            return "The server couldn't handle the request (\(code))."
        case .decoding:
            return "We received unexpected data from the server."
        }
    }
}

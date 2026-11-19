//
//  APIErrorTests.swift
//  LocalEventsExplorer_AETests
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Tests for APIError mapping and messages.

import Foundation
@testable import LocalEventsExplorer_AE
import Testing

@Suite("APIError")
@MainActor
struct APIErrorTests {
    @Test("Connectivity URLErrors map to .offline", arguments: [
        URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed
    ])
    func offlineCodes(code: URLError.Code) {
        #expect(APIError(URLError(code)) == .offline)
    }

    @Test("Timeouts map to .timeout and other codes to .transport")
    func timeoutAndTransport() {
        #expect(APIError(URLError(.timedOut)) == .timeout)
        #expect(APIError(URLError(.cannotFindHost)) == .transport(.cannotFindHost))
    }

    @Test("Every case has a user-facing message")
    func messages() {
        let cases: [APIError] = [
            .offline, .timeout, .invalidResponse, .httpStatus(404), .httpStatus(503),
            .decoding("x"), .transport(.cannotFindHost)
        ]
        for error in cases {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }
}

//
//  MapsNavigator.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Deep link to Apple Maps for driving directions to an event.

import Foundation
import UIKit

@MainActor
protocol MapsNavigator {
    func openDirections(to event: Event)
}

@MainActor
final class AppleMapsNavigator: MapsNavigator {
    func openDirections(to event: Event) {
        guard let url = Self.directionsURL(to: event) else { return }
        UIApplication.shared.open(url)
    }

    /// `https://maps.apple.com/?daddr=<lat>,<lon>&dirflg=d&q=<title>` opens the Maps app with driving directions.
    static func directionsURL(to event: Event) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.path = "/"
        components.queryItems = [
            URLQueryItem(name: "daddr", value: "\(event.latitude),\(event.longitude)"),
            URLQueryItem(name: "dirflg", value: "d"),
            URLQueryItem(name: "q", value: event.title)
        ]
        return components.url
    }
}

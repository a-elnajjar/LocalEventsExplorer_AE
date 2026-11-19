//
//  LocationService.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  One-shot location lookup with "When In Use" permission. No continuous tracking, to save battery.
//  Assumes one request in flight at a time (true for how the view models call it): a second call
//  while one is pending would replace the stored continuation instead of joining it.

import CoreLocation

enum LocationAuthorization: Equatable {
    case notDetermined
    case authorized
    case denied
}

@MainActor
protocol LocationService: AnyObject {
    var authorization: LocationAuthorization { get }
    func requestCurrentLocation() async -> CLLocation?
}

@MainActor
final class CoreLocationService: NSObject, LocationService {
    private let manager: CLLocationManager
    private var authorizationContinuation: CheckedContinuation<Void, Never>?
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorization: LocationAuthorization {
        Self.map(manager.authorizationStatus)
    }

    func requestCurrentLocation() async -> CLLocation? {
        if authorization == .notDetermined {
            await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }
        guard authorization == .authorized else { return nil }

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private static func map(_ status: CLAuthorizationStatus) -> LocationAuthorization {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
}

extension CoreLocationService: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        authorizationContinuation?.resume()
        authorizationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.last)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}

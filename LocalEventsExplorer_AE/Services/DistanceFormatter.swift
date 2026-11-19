//
//  DistanceFormatter.swift
//  LocalEventsExplorer_AE
//
//  Created by Abdalla Elnajjar on 2026-11-19.
//  Distance calculation and formatting ("847 m", "2.3 km", "1.4 mi") in the user's units.
//  Uses Foundation's MeasurementFormatter so km/mi conversion and unit symbols aren't hand-rolled.

import CoreLocation
import Foundation

enum DistanceFormatter {
    static func meters(from location: CLLocation, to event: Event) -> CLLocationDistance {
        location.distance(from: CLLocation(latitude: event.latitude, longitude: event.longitude))
    }

    static func distance(from location: CLLocation, to event: Event, locale: Locale = .current) -> String {
        format(meters: meters(from: location, to: event), locale: locale)
    }

    /// Meters under 1 km, km above that; miles when the locale uses the imperial system.
    static func format(meters: CLLocationDistance, locale: Locale = .current) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let isImperial = locale.measurementSystem != .metric

        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit

        switch (isImperial, meters) {
        case (true, _):
            formatter.numberFormatter.maximumFractionDigits = 1
            return formatter.string(from: measurement.converted(to: .miles))
        case (false, ..<1_000):
            formatter.numberFormatter.maximumFractionDigits = 0
            return formatter.string(from: measurement)
        default:
            formatter.numberFormatter.maximumFractionDigits = 1
            return formatter.string(from: measurement.converted(to: .kilometers))
        }
    }
}

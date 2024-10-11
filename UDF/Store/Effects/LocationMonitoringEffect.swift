//===--- LocationMonitoringEffect.swift ------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Combine
import CoreLocation
import Foundation

public extension Effects {
    /// `LocationMonitoringEffect` is an effect that monitors location updates using `CLLocationManager`.
    /// It can be configured with a distance filter or with a custom configuration block for the `CLLocationManager`.
    struct LocationMonitoringEffect: Effectable {
        private var locationManagerConfigurator: (CLLocationManager) -> Void = { _ in }

        /// Initializes a new `LocationMonitoringEffect` instance with a specified distance filter.
        /// - Parameter distanceFilter: The minimum distance (measured in meters) a device must move
        ///   horizontally before an update event is generated. The default is 100 meters.
        public init(distanceFilter: CLLocationDistance = 100) {
            locationManagerConfigurator = {
                $0.distanceFilter = distanceFilter
            }
        }

        /// Initializes a new `LocationMonitoringEffect` instance with a custom configuration block.
        /// - Parameter locationManagerConfigurator: A closure that allows for custom configuration of the `CLLocationManager`.
        public init(configure locationManagerConfigurator: @escaping (CLLocationManager) -> Void) {
            self.locationManagerConfigurator = locationManagerConfigurator
        }

        /// The upstream publisher that produces location update actions.
        public var upstream: AnyPublisher<any Action, Never> {
            self.eraseToAnyPublisher()
        }

        /// Receives a subscriber and starts monitoring location updates.
        public func receive<S>(subscriber: S) where S: Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            let locationManager = CLLocationManager()
            locationManagerConfigurator(locationManager)

            subscriber.receive(
                subscription: LocationMonitoringSubscription(
                    subscriber: subscriber,
                    locationManager: locationManager
                )
            )
        }

        /// A private subscription class that manages location updates.
        private final class LocationMonitoringSubscription<S: Subscriber>: NSObject, CLLocationManagerDelegate,
            Subscription where S.Input == any Action
        {
            var subscriber: S?
            private let locationManager: CLLocationManager

            /// Initializes a new subscription with a subscriber and a location manager.
            init(subscriber: S, locationManager: CLLocationManager) {
                self.locationManager = locationManager
                super.init()
                self.subscriber = subscriber
                locationManager.delegate = self
            }

            /// Requests a specified number of values from the publisher.
            func request(_ demand: Subscribers.Demand) {
                locationManager.startUpdatingLocation()
            }

            /// Cancels the subscription and stops location updates.
            func cancel() {
                locationManager.stopUpdatingLocation()
                subscriber = nil
            }

            /// Called when the location manager updates the location.
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                sendLocation(locations.last)
            }

            /// Called when the location manager starts monitoring for a region.
            func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
                sendLocation(manager.location)
            }

            /// Sends the current location to the subscriber.
            private func sendLocation(_ location: CLLocation?) {
                guard let location, CLLocationCoordinate2DIsValid(location.coordinate) else {
                    return
                }

                _ = subscriber?.receive(Actions.DidUpdateUserLocation(location: location))
            }
        }
    }
}

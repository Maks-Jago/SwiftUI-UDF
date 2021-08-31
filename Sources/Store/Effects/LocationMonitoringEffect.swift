//
//  LocationMonitoringEffect.swift
//  
//
//  Created by Max Kuznetsov on 31.08.2021.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI_UDF_Binary

public extension Effects {

    struct LocationMonitoringEffect: Effectable {

        private var locationManagerConfigurator: (CLLocationManager) -> Void = { _ in }

        public init() {}

        public init(distanceFilter: CLLocationDistance) {
            locationManagerConfigurator = {
                $0.distanceFilter = distanceFilter
            }
        }

        public init(configure locationManagerConfigurator: @escaping (CLLocationManager) -> Void) {
            self.locationManagerConfigurator = locationManagerConfigurator
        }

        public var upstream: AnyPublisher<AnyAction, Never> {
            self.eraseToAnyPublisher()
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            let locationManager = CLLocationManager()
            locationManagerConfigurator(locationManager)

            subscriber.receive(
                subscription: LocationMonitoringSubscription(
                    subscriber: subscriber,
                    locationManager: locationManager
                )
            )
        }

        private final class LocationMonitoringSubscription<S: Subscriber>: NSObject, CLLocationManagerDelegate, Subscription where S.Input == AnyAction {
            var subscriber: S?

            private let locationManager: CLLocationManager
            private var lastTrackedTime: Date? = nil

            init(subscriber: S, locationManager: CLLocationManager) {
                self.locationManager = locationManager
                super.init()
                self.subscriber = subscriber
                locationManager.delegate = self
            }

            func request(_ demand: Subscribers.Demand) {
                locationManager.startUpdatingLocation()
            }

            func cancel() {
                locationManager.stopUpdatingLocation()
                subscriber = nil
            }

            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                sendLocation(locations.last)
            }

            func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
                sendLocation(manager.location)
            }

            private func sendLocation(_ location: CLLocation?) {
                guard let location = location else {
                    return
                }

                if let lastTrackedTime = lastTrackedTime, lastTrackedTime.timeIntervalSince(Date()) < 2 {
                    return
                }

                lastTrackedTime = Date()
                _ = subscriber?.receive(Actions.DidUpdateUserLocation(location: location).eraseToAnyAction())
            }
        }
    }
}

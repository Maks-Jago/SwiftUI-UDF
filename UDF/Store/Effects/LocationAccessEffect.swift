//===--- LocationAccessEffect.swift ----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Combine
import CoreLocation

public extension Effects {
    
    /// `LocationAccessEffect` is an effect that monitors changes in the location authorization status.
    /// It uses `CLLocationManager` to observe the location services' authorization and accuracy.
    struct LocationAccessEffect: Effectable {
        
        /// Creates a new `LocationAccessEffect` instance.
        public init() {}
        
        /// The upstream publisher that produces location access actions.
        public var upstream: AnyPublisher<any Action, Never> {
            self.eraseToAnyPublisher()
        }
        
        /// Receives a subscriber and starts monitoring the location authorization status.
        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(subscription: LocationSubscription(subscriber: subscriber))
        }
        
        /// A private subscription class that manages location updates.
        private final class LocationSubscription<S: Subscriber>: NSObject, CLLocationManagerDelegate, Subscription where S.Input == any Action {
            
            var subscriber: S?
            private let locationManager = CLLocationManager()
            
            /// Initializes a new subscription with a subscriber.
            init(subscriber: S) {
                super.init()
                self.subscriber = subscriber
                locationManager.delegate = self
            }
            
            /// Requests a specified number of values from the publisher.
            func request(_ demand: Subscribers.Demand) {
                guard demand > 0 else {
                    return
                }
                
                send(status: locationManager.authorizationStatus, accuracyAuthorization: locationManager.accuracyAuthorization)
            }
            
            /// Cancels the subscription.
            func cancel() {
                subscriber = nil
            }
            
            /// Called when the location manager's authorization status changes.
            func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
                send(status: manager.authorizationStatus, accuracyAuthorization: manager.accuracyAuthorization)
            }
            
            /// Sends the current location access status to the subscriber.
            private func send(status: CLAuthorizationStatus, accuracyAuthorization: CLAccuracyAuthorization) {
                DispatchQueue.global().async { [weak self] in
                    let action = Actions.DidUpdateLocationAccess(
                        locationServicesEnabled: CLLocationManager.locationServicesEnabled(),
                        access: status,
                        accuracyAuthorization: accuracyAuthorization
                    )
                    _ = self?.subscriber?.receive(action)
                }
            }
        }
    }
}

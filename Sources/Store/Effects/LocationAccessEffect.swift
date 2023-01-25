//
//  LocationAccessEffect.swift
//  
//
//  Created by Max Kuznetsov on 31.08.2021.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI_UDF_Binary

public extension Effects {

    struct LocationAccessEffect: Effectable {
        public init() {}

        public var upstream: AnyPublisher<any Action, Never> {
            self.eraseToAnyPublisher()
        }

        public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(subscription: LocationSubscription(subscriber: subscriber))
        }

        private final class LocationSubscription<S: Subscriber>: NSObject, CLLocationManagerDelegate, Subscription where S.Input == any Action {
            var subscriber: S?

            private let locationManager = CLLocationManager()

            init(subscriber: S) {
                super.init()
                self.subscriber = subscriber
                locationManager.delegate = self
            }

            func request(_ demand: Subscribers.Demand) {
                guard demand > 0 else {
                    return
                }

                send(status: locationManager.authorizationStatus, accuracyAuthorization: locationManager.accuracyAuthorization)
            }

            func cancel() {
                subscriber = nil
            }

            func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
                send(status: manager.authorizationStatus, accuracyAuthorization: manager.accuracyAuthorization)
            }

            private func send(status: CLAuthorizationStatus, accuracyAuthorization: CLAccuracyAuthorization) {
                let action = Actions.DidUpdateLocationAccess(access: status, accuracyAuthorization: accuracyAuthorization)
                _ = subscriber?.receive(action)
            }
        }
    }
}

//
//  SecurityView.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-12-03.
//
import SwiftUI
import LocalAuthentication
import CoreLocation
import CoreData

struct FaceIDAuthView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack {
            // Display the Face ID image
            Image("FaceID")
                .resizable()
                .frame(width: 80, height: 80)
                .padding(.bottom, 10)

            Text("Authenticate with Face ID to continue")
                .font(.headline)
                .padding()

            Button("Retry Authentication") {
                authenticateWithFaceID()
            }
            .padding()
        }
    }

    private func authenticateWithFaceID() {
        let context = LAContext()
        var error: NSError?

        // Check if Face ID is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to use the app") { success, error in
                DispatchQueue.main.async {
                    if success {
                        isAuthenticated = true
                    } else {
                        print("Authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Face ID not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
}

struct LocationBlankPage: View {
    @ObservedObject var locationManager: LocationManager
    var message: String

    var body: some View {
        VStack {
            // Display the Location image
            Image("Location")
                .resizable()
                .frame(width: 80, height: 80)
                .padding(.bottom, 10)

            // Display the message
            Text(message)
                .font(.headline)
                .padding()

            // Add a button for location access
            Button("Grant Location Access") {
                locationManager.requestLocationPermission()
            }
            .padding()
        }
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()

    @Published var permissionDenied = false
    @Published var isInCanada = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkLocationPermission()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func checkLocationPermission() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            requestLocationPermission()
        case .restricted, .denied:
            permissionDenied = true
        case .authorizedAlways, .authorizedWhenInUse:
            permissionDenied = false
            locationManager.startUpdatingLocation()
        @unknown default:
            permissionDenied = true
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.checkLocationPermission()
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.locationManager.startUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // Use reverse geocoding to determine if the user is in Canada
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isInCanada = false
                }
                return
            }

            if let placemark = placemarks?.first {
                if let country = placemark.country {
                    print("Detected country: \(country)") // Debug
                    DispatchQueue.main.async {
                        self.isInCanada = (country.contains("Canada") || country.lowercased() == "ca")
                    }
                } else {
                    print("Country not found in placemark.") // Debug
                    DispatchQueue.main.async {
                        self.isInCanada = false
                    }
                }
            } else {
                print("No placemarks found.") // Debug
                DispatchQueue.main.async {
                    self.isInCanada = false
                }
            }
        }

        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}

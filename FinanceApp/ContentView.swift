//
//  ContentView.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-11-21.
import SwiftUI
import CoreData
import LocalAuthentication
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isAuthenticated = false

    var body: some View {
        Group {
            if isAuthenticated && !locationManager.permissionDenied && locationManager.isInCanada {
                // Navigate to FinanceAppView when Face ID and Location are valid
                FinanceAppView()
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            } else if !isAuthenticated {
                // Face ID authentication screen
                FaceIDAuthView(isAuthenticated: $isAuthenticated)
            } else {
                // Location permission issue or not in Canada
                BlankPage(locationManager: locationManager, message: "Location permission denied or invalid location. Please allow access or move to a valid location.")
            }
        }
        .onAppear {
            // Check location permission and trigger Face ID authentication on launch
            locationManager.checkLocationPermission()
            if !isAuthenticated {
                authenticateWithFaceID()
            }
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
                        isAuthenticated = false
                        print("Authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Face ID not available: \(error?.localizedDescription ?? "Unknown error")")
            isAuthenticated = false
        }
    }
}

struct FaceIDAuthView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        VStack {
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

struct BlankPage: View {
    @ObservedObject var locationManager: LocationManager
    var message: String

    var body: some View {
        VStack {
            Text(message)
                .font(.headline)
                .padding()

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

// MARK: - PersistenceController

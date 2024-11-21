//
//  ContentView.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-11-21.
import SwiftUI
import LocalAuthentication
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isAuthenticated = false

    var body: some View {
        if isAuthenticated {
            if locationManager.permissionDenied {
                // Blank Page with Location Request Button
                BlankPage(locationManager: locationManager)
            } else {
                // Display FinanceAppView when Face ID and Location are granted
                FinanceAppView()
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        } else {
            // Face ID Authentication Screen
            FaceIDAuthView(isAuthenticated: $isAuthenticated)
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

            Button("Authenticate") {
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

    var body: some View {
        VStack {
            Text("Location permission denied.")
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

    override init() {
        super.init()
        locationManager.delegate = self
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
        @unknown default:
            permissionDenied = true
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.checkLocationPermission()
        }
    }
}

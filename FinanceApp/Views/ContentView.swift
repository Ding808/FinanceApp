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
                LocationBlankPage(locationManager: locationManager, message: "Location permission denied or invalid location. Please allow access or move to a valid location.")
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

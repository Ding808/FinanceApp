//
//  FinanceAppApp.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-11-21.
//

import SwiftUI
import CoreData

@main
struct FinanceAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            FinanceAppView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

//
//  MrtCardScannerApp.swift
//  MrtCardScanner
//
//  Created by Aung Ko Min on 10/7/23.
//

import SwiftUI

@main
struct MrtCardScannerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

//
//  DeFilmsApp.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI
import CoreData

@main
struct DeFilmsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

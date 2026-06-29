//
//  QuotationsApp.swift
//  Quotations
//

import SwiftUI
import SwiftData

@main
struct QuotationsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Author.self,
            Source.self,
            Quotation.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)
            QuotationLocationMigration.migrateIfNeeded(context: context)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup("") {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

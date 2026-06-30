//
//  QuotationsApp.swift
//  Quotations
//

import SwiftUI
import SwiftData

@main
struct QuotationsApp: App {
    private let sharedModelContainer: ModelContainer
    private let containerLoadWarning: String?

    init() {
        let schema = Schema([
            Author.self,
            Source.self,
            Quotation.self,
        ])
        let persistentConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [persistentConfiguration])
            let context = ModelContext(container)
            QuotationLocationMigration.migrateIfNeeded(
                context: context,
                storeURL: persistentConfiguration.url
            )
            sharedModelContainer = container
            containerLoadWarning = nil
        } catch {
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                let context = ModelContext(container)
                QuotationLocationMigration.migrateIfNeeded(
                    context: context,
                    storeURL: fallbackConfiguration.url
                )
                sharedModelContainer = container
                containerLoadWarning = "Your library could not be opened (\(error.localizedDescription)). A temporary in-memory library is being used instead."
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup("Quotations", id: "MainQuotationsWindow") {
            RootView(loadWarning: containerLoadWarning)
                .modelContainer(sharedModelContainer)
        }
    }
}

private struct RootView: View {
    let loadWarning: String?
    @State private var showLoadWarning = false

    var body: some View {
        ContentView()
            .onAppear {
                showLoadWarning = loadWarning != nil
            }
            .alert("Library Warning", isPresented: $showLoadWarning) {
                Button("OK", role: .cancel) {}
            } message: {
                if let loadWarning {
                    Text(loadWarning)
                }
            }
    }
}

//
//  QuotationsApp.swift
//  Quotations
//

import SwiftUI
import SwiftData

@main
struct QuotationsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var deepLinkRouter = DeepLinkRouter()

    private let sharedModelContainer: ModelContainer
    private let containerLoadWarning: String?
    private let backupManager: BackupManager

    init() {
        let schema = Schema([
            Author.self,
            Source.self,
            Quotation.self
        ])
        try? AppGroupStore.migrateLegacyStoreIfNeeded(schema: schema)
        let persistentConfiguration = AppGroupStore.modelConfiguration(schema: schema)

        BackupManager.applyPendingRestoreIfNeeded(storeURL: persistentConfiguration.url)

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
                containerLoadWarning =
                    "Your library could not be opened (\(error.localizedDescription)). " +
                    "A temporary in-memory library is being used instead."
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }

        backupManager = BackupManager(storeURL: persistentConfiguration.url)
    }

    var body: some Scene {
        WindowGroup("Quotations", id: "MainQuotationsWindow") {
            RootView(loadWarning: containerLoadWarning)
                .modelContainer(sharedModelContainer)
                .environment(backupManager)
                .environment(deepLinkRouter)
                .handlesExternalEvents(preferring: ["quotation"], allowing: ["*"])
        }
        .handlesExternalEvents(matching: ["quotation"])
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Quotation") {
                    NotificationCenter.default.post(name: .addQuotation, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            CommandGroup(after: .saveItem) {
                Button("Import from Apple Books…") {
                    NotificationCenter.default.post(name: .importFromAppleBooks, object: nil)
                }
                Button("Import Quotations from CSV…") {
                    NotificationCenter.default.post(name: .importQuotationsFromCSV, object: nil)
                }
                Button("Backups…") {
                    NotificationCenter.default.post(name: .showBackupsPanel, object: nil)
                }
                .keyboardShortcut("B", modifiers: [.command, .shift])
            }
        }
    }
}

private struct RootView: View {
    let loadWarning: String?
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
    @State private var showLoadWarning = false

    var body: some View {
        ContentView()
            .onAppear {
                showLoadWarning = loadWarning != nil
                DeepLinkLaunchQueue.flush(into: deepLinkRouter)
            }
            .onOpenURL { url in
                deepLinkRouter.enqueue(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .quotationDeepLinkReceived)) { _ in
                DeepLinkLaunchQueue.flush(into: deepLinkRouter)
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

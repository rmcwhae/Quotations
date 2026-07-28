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
    @State private var stopWordsStore = StopWordsStore()
    @State private var libraryMode: LibraryModeController

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

        let personalContainer: ModelContainer
        let loadWarning: String?
        do {
            let container = try ModelContainer(for: schema, configurations: [persistentConfiguration])
            let context = ModelContext(container)
            QuotationLocationMigration.migrateIfNeeded(
                context: context,
                storeURL: persistentConfiguration.url
            )
            personalContainer = container
            loadWarning = nil
        } catch {
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                let context = ModelContext(container)
                QuotationLocationMigration.migrateIfNeeded(
                    context: context,
                    storeURL: fallbackConfiguration.url
                )
                personalContainer = container
                loadWarning =
                    "Your library could not be opened (\(error.localizedDescription)). " +
                    "A temporary in-memory library is being used instead."
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }

        containerLoadWarning = loadWarning
        backupManager = BackupManager(storeURL: persistentConfiguration.url)
        _libraryMode = State(initialValue: LibraryModeController(personalContainer: personalContainer))
    }

    var body: some Scene {
        WindowGroup(libraryMode.windowTitle, id: "MainQuotationsWindow") {
            RootView(loadWarning: containerLoadWarning)
                .modelContainer(libraryMode.activeContainer)
                .environment(backupManager)
                .environment(deepLinkRouter)
                .environment(stopWordsStore)
                .environment(libraryMode)
                .id(libraryMode.isDemoMode)
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
        }
        .handlesExternalEvents(matching: ["*"])
        .commands {
            CommandMenu("Find") {
                Button("Find…") {
                    NotificationCenter.default.post(name: .focusFindInPage, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
            CommandMenu("Advanced Search") {
                Button("Show Advanced Search") {
                    NotificationCenter.default.post(name: .openAdvancedSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
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
                .disabled(libraryMode.isDemoMode)
                Button("Import from Kobo annotations text file…") {
                    NotificationCenter.default.post(name: .importFromKoboAnnotations, object: nil)
                }
                .disabled(libraryMode.isDemoMode)
                Button("Import Quotations from CSV…") {
                    NotificationCenter.default.post(name: .importQuotationsFromCSV, object: nil)
                }
                .disabled(libraryMode.isDemoMode)
                Button("Backups…") {
                    NotificationCenter.default.post(name: .showBackupsPanel, object: nil)
                }
                .keyboardShortcut("B", modifiers: [.command, .shift])
                .disabled(libraryMode.isDemoMode)
                Divider()
                Toggle("Demo Mode", isOn: libraryMode.isDemoModeBinding)
            }
        }

        Settings {
            SettingsView()
                .environment(stopWordsStore)
        }
    }
}

private struct RootView: View {
    let loadWarning: String?
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
    @Environment(LibraryModeController.self) private var libraryMode
    @Environment(\.modelContext) private var modelContext
    @State private var showLoadWarning = false

    var body: some View {
        ContentView()
            .onAppear {
                showLoadWarning = loadWarning != nil && !libraryMode.isDemoMode
                DeepLinkLaunchQueue.flush(into: deepLinkRouter)
                prepareSearchIndexes()
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

    private func prepareSearchIndexes() {
        Task {
            QuotationSearchIndexManager.invalidateFingerprint()
            if libraryMode.isDemoMode {
                await QuotationSearchIndexManager.reindexIfNeeded(modelContext: modelContext)
            } else {
                await EmbeddingSearchIndex.shared.reloadPersistedSnapshot()
                await QuotationSearchIndexManager.reindexIfNeeded(modelContext: modelContext)
            }
        }
    }
}

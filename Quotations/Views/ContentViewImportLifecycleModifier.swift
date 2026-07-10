//
//  ContentViewImportLifecycleModifier.swift
//  Quotations
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentViewImportLifecycleModifier: ViewModifier {
    @Binding var showCSVImporter: Bool
    @Binding var showBackups: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    let onImportCSV: (URL) -> Void
    let onBeginCSVImport: () -> Void
    let onImportFromAppleBooks: () -> Void
    let onAddQuotation: () -> Void
    let onOpenAdvancedSearch: () -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .showBackupsPanel)) { _ in
                showBackups = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .focusFindInPage)) { _ in
                ToolbarFindFocus.activate()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openAdvancedSearch)) { _ in
                onOpenAdvancedSearch()
            }
            .onReceive(NotificationCenter.default.publisher(for: .importFromAppleBooks)) { _ in
                onImportFromAppleBooks()
            }
            .onReceive(NotificationCenter.default.publisher(for: .importQuotationsFromCSV)) { _ in
                onBeginCSVImport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .addQuotation)) { _ in
                onAddQuotation()
            }
            .fileImporter(
                isPresented: $showCSVImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    onImportCSV(url)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            .navigationTitle("")
    }
}

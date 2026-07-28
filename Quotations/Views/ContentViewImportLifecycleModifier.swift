//
//  ContentViewImportLifecycleModifier.swift
//  Quotations
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum ContentViewFileImportKind {
    case csv
    case koboAnnotations
}

struct ContentViewImportLifecycleModifier: ViewModifier {
    @Binding var showFileImporter: Bool
    @Binding var fileImportKind: ContentViewFileImportKind
    @Binding var showBackups: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String?
    let onImportCSV: (URL) -> Void
    let onBeginCSVImport: () -> Void
    let onImportFromAppleBooks: () -> Void
    let onBeginKoboImport: () -> Void
    let onImportFromKoboAnnotations: (URL) -> Void
    let onAddQuotation: () -> Void
    let onOpenAdvancedSearch: () -> Void

    private var allowedContentTypes: [UTType] {
        switch fileImportKind {
        case .csv:
            [.commaSeparatedText, .plainText, .text]
        case .koboAnnotations:
            [.plainText, .text]
        }
    }

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
            .onReceive(NotificationCenter.default.publisher(for: .importFromKoboAnnotations)) { _ in
                onBeginKoboImport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .importQuotationsFromCSV)) { _ in
                onBeginCSVImport()
            }
            .onReceive(NotificationCenter.default.publisher(for: .addQuotation)) { _ in
                onAddQuotation()
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: allowedContentTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    switch fileImportKind {
                    case .csv:
                        onImportCSV(url)
                    case .koboAnnotations:
                        onImportFromKoboAnnotations(url)
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            .navigationTitle("")
    }
}

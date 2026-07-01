//
//  ContentViewSheetsModifier.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct ContentViewSheetsModifier: ViewModifier {
    @Binding var showError: Bool
    let errorMessage: String?
    @Binding var showImportSuccess: Bool
    let importSuccessMessage: String?
    @Binding var showAuthorList: Bool
    @Binding var showBackups: Bool
    @Binding var newSourceSession: NewSourceSheetSession?
    @Binding var sourceToEdit: Source?
    @Binding var showDeleteSourceConfirmation: Bool
    @Binding var sourceToDelete: Source?
    @Binding var showDeleteQuotationConfirmation: Bool
    @Binding var selectedSourceId: PersistentIdentifier?
    @Binding var selectedQuotationId: PersistentIdentifier?
    let modelContext: ModelContext
    let onEditError: (String) -> Void
    let onSourceCreated: (PersistentIdentifier) -> Void

    func body(content: Content) -> some View {
        content
            .modifier(ContentViewAlertsModifier(
                showError: $showError,
                errorMessage: errorMessage,
                showImportSuccess: $showImportSuccess,
                importSuccessMessage: importSuccessMessage
            ))
            .sheet(isPresented: $showAuthorList) {
                AuthorListView(onDismiss: { showAuthorList = false })
            }
            .sheet(isPresented: $showBackups) {
                BackupManagementView(onDismiss: { showBackups = false })
            }
            .sheet(item: $newSourceSession) { _ in
                SourceFormView(
                    onSuccess: { sourceId in
                        newSourceSession = nil
                        if let sourceId {
                            onSourceCreated(sourceId)
                        }
                    },
                    onCancel: { newSourceSession = nil },
                    onError: onEditError
                )
            }
            .sheet(item: $sourceToEdit) { source in
                SourceFormView(
                    existingSource: source,
                    onSuccess: { _ in sourceToEdit = nil },
                    onCancel: { sourceToEdit = nil },
                    onError: onEditError
                )
            }
            .modifier(DeleteSourceConfirmationModifier(
                isPresented: $showDeleteSourceConfirmation,
                sourceToDelete: $sourceToDelete,
                selectedSourceId: $selectedSourceId,
                selectedQuotationId: $selectedQuotationId,
                modelContext: modelContext,
                onEditError: onEditError
            ))
            .modifier(DeleteQuotationConfirmationModifier(
                isPresented: $showDeleteQuotationConfirmation,
                selectedQuotationId: $selectedQuotationId,
                modelContext: modelContext,
                onEditError: onEditError
            ))
    }
}

private struct ContentViewAlertsModifier: ViewModifier {
    @Binding var showError: Bool
    let errorMessage: String?
    @Binding var showImportSuccess: Bool
    let importSuccessMessage: String?

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Import Complete", isPresented: $showImportSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                if let importSuccessMessage {
                    Text(importSuccessMessage)
                }
            }
    }
}

struct DeleteSourceConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var sourceToDelete: Source?
    @Binding var selectedSourceId: PersistentIdentifier?
    @Binding var selectedQuotationId: PersistentIdentifier?
    let modelContext: ModelContext
    let onEditError: (String) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Delete Source?",
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedSource()
            }
            .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {
                sourceToDelete = nil
            }
        } message: {
            if let source = sourceToDelete {
                Text("\"\(source.title)\" and all its quotations will be removed.")
            }
        }
    }

    private func deleteSelectedSource() {
        if let source = sourceToDelete {
            let sourceId = source.persistentModelID
            do {
                try SoftDelete.source(source, in: modelContext)
            } catch {
                onEditError(error.localizedDescription)
            }
            if selectedSourceId == sourceId {
                selectedSourceId = nil
                selectedQuotationId = nil
            }
        }
        sourceToDelete = nil
    }
}

struct DeleteQuotationConfirmationModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var selectedQuotationId: PersistentIdentifier?
    let modelContext: ModelContext
    let onEditError: (String) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Remove quotation?",
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                deleteSelectedQuotation()
            }
            .keyboardShortcut(.defaultAction)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This quotation will be removed from your library.")
        }
    }

    private func deleteSelectedQuotation() {
        guard let id = selectedQuotationId,
              let quotation = modelContext.model(for: id) as? Quotation,
              quotation.deletedAt == nil else { return }
        do {
            try SoftDelete.quotation(quotation, in: modelContext)
        } catch {
            onEditError(error.localizedDescription)
        }
        selectedQuotationId = nil
    }
}

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
    @Binding var showSourceCreateForm: Bool
    @Binding var sourceToEdit: Source?
    @Binding var showDeleteSourceConfirmation: Bool
    @Binding var sourceToDelete: Source?
    @Binding var selectedSourceId: PersistentIdentifier?
    @Binding var selectedQuotationId: PersistentIdentifier?
    let modelContext: ModelContext
    let onEditError: (String) -> Void
    let onSourceCreated: (PersistentIdentifier) -> Void

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
            .sheet(isPresented: $showAuthorList) {
                AuthorListView(onDismiss: { showAuthorList = false })
            }
            .sheet(isPresented: $showBackups) {
                BackupManagementView(onDismiss: { showBackups = false })
            }
            .sheet(isPresented: $showSourceCreateForm) {
                SourceFormView(
                    onSuccess: { sourceId in
                        showSourceCreateForm = false
                        if let sourceId {
                            onSourceCreated(sourceId)
                        }
                    },
                    onCancel: { showSourceCreateForm = false },
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

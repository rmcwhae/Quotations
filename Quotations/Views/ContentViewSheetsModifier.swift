//
//  ContentViewSheetsModifier.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct ContentViewSheetsModifier: ViewModifier {
    @Binding var showError: Bool
    let errorMessage: String?
    @Binding var showAuthorList: Bool
    @Binding var showBackups: Bool
    @Binding var sourceToEdit: Source?
    @Binding var showDeleteSourceConfirmation: Bool
    @Binding var sourceToDelete: Source?
    @Binding var selectedSourceId: PersistentIdentifier?
    @Binding var selectedQuotationId: PersistentIdentifier?
    let modelContext: ModelContext
    let onEditError: (String) -> Void

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showAuthorList) {
                AuthorListView(onDismiss: { showAuthorList = false })
            }
            .sheet(isPresented: $showBackups) {
                BackupManagementView(onDismiss: { showBackups = false })
            }
            .sheet(item: $sourceToEdit) { source in
                SourceFormView(
                    existingSource: source,
                    onSuccess: { sourceToEdit = nil },
                    onCancel: { sourceToEdit = nil },
                    onError: onEditError
                )
                .padding()
                .frame(minWidth: 360, minHeight: 420)
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

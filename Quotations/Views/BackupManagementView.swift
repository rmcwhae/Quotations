//
//  BackupManagementView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct BackupManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(BackupManager.self) private var backupManager

    var onDismiss: () -> Void

    @State private var backupToRestore: Backup?
    @State private var backupToDelete: Backup?
    @State private var showRestoreConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if backupManager.backups.isEmpty {
                emptyState
            } else {
                backupList
            }
        }
        .frame(minWidth: 420, minHeight: 360)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .confirmationDialog(
            "Restore Backup?",
            isPresented: $showRestoreConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restore and Relaunch", role: .destructive) {
                restoreSelectedBackup()
            }
            Button("Cancel", role: .cancel) {
                backupToRestore = nil
            }
        } message: {
            if let backup = backupToRestore {
                Text(
                    "Your current library will be replaced with the backup from " +
                    "\(backup.createdAt.formatted(date: .abbreviated, time: .shortened)). " +
                    "A safety snapshot of the current library will be created first. " +
                    "The app will relaunch to apply the restore."
                )
            }
        }
        .confirmationDialog(
            "Delete Backup?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedBackup()
            }
            Button("Cancel", role: .cancel) {
                backupToDelete = nil
            }
        } message: {
            if let backup = backupToDelete {
                Text("Delete the backup from \(backup.createdAt.formatted(date: .abbreviated, time: .shortened))?")
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Backups")
                .font(.headline)
            Spacer()
            Button {
                createBackup()
            } label: {
                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Label("Create Backup", systemImage: "plus")
                }
            }
            .disabled(isWorking)
            .accessibilityLabel("Create backup")
            .help("Create backup")
            Button("Done") {
                onDismiss()
            }
            .accessibilityLabel("Close backups panel")
            .help("Close backups panel")
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No backups yet.")
                .foregroundStyle(.secondary)
            Text("Create a backup before a batch import or other large change.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var backupList: some View {
        List {
            ForEach(backupManager.backups) { backup in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(backup.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.body)
                        if backup.isSafetyBackup {
                            Text("Safety")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    Text(backup.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(backup.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .contextMenu {
                    Button("Restore…") {
                        backupToRestore = backup
                        showRestoreConfirmation = true
                    }
                    Button("Delete", role: .destructive) {
                        backupToDelete = backup
                        showDeleteConfirmation = true
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        backupToDelete = backup
                        showDeleteConfirmation = true
                    }
                    Button("Restore") {
                        backupToRestore = backup
                        showRestoreConfirmation = true
                    }
                    .tint(.accentColor)
                }
            }
        }
    }

    private func createBackup() {
        isWorking = true
        defer { isWorking = false }

        do {
            try modelContext.save()
            _ = try backupManager.createBackup()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func restoreSelectedBackup() {
        guard let backup = backupToRestore else { return }
        backupToRestore = nil
        isWorking = true

        do {
            try modelContext.save()
            try backupManager.requestRestore(backup)
        } catch {
            isWorking = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func deleteSelectedBackup() {
        guard let backup = backupToDelete else { return }
        backupToDelete = nil

        do {
            try backupManager.deleteBackup(backup)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    BackupManagementView(onDismiss: {})
        .environment(BackupManager(storeURL: URL(fileURLWithPath: "/tmp/default.store")))
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}

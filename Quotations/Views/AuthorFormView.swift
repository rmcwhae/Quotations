//
//  AuthorFormView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct AuthorFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Author> { $0.deletedAt == nil }, sort: \Author.name)
    private var authors: [Author]

    var existingAuthor: Author?
    var onSuccess: () -> Void
    var onCancel: () -> Void

    @State private var name = ""
    @State private var hasPrefilled = false
    /// Shown inside the sheet: an alert on the presenting view can't appear while this sheet is up.
    @State private var saveError: String?

    private var isEditing: Bool { existingAuthor != nil }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nameIsTaken: Bool {
        let key = trimmedName.lowercased()
        return authors.contains { $0.id != existingAuthor?.id && $0.name.lowercased() == key }
    }

    private var validationMessage: String? {
        nameIsTaken ? "An author with this name already exists." : saveError
    }

    var body: some View {
        Form {
            LabeledContent("Author name") {
                MacFormTextField(placeholder: "", text: $name)
            }
            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .contentMargins(.bottom, 0, for: .scrollContent)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minWidth: 280)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { onCancel() }
                    .accessibilityLabel("Cancel")
                    .help("Cancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save" : "Add") { submit() }
                    .accessibilityLabel(isEditing ? "Save author" : "Add author")
                    .help(isEditing ? "Save changes" : "Add author")
                    .disabled(trimmedName.isEmpty || nameIsTaken)
            }
        }
        .onChange(of: name) { _, _ in saveError = nil }
        .onAppear {
            guard let author = existingAuthor, !hasPrefilled else { return }
            name = author.name
            hasPrefilled = true
        }
    }

    private func submit() {
        guard !trimmedName.isEmpty, !nameIsTaken else { return }
        do {
            if let existing = existingAuthor {
                existing.name = trimmedName
                existing.updatedAt = Date()
            } else {
                modelContext.insert(Author(name: trimmedName))
            }
            try modelContext.saveAndNotify()
            onSuccess()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

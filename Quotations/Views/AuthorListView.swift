//
//  AuthorListView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct AuthorListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Author> { $0.deletedAt == nil }, sort: \Author.name)
    private var authors: [Author]
    @Query(filter: #Predicate<Source> { $0.deletedAt == nil })
    private var sources: [Source]

    var onDismiss: () -> Void

    @State private var authorToEdit: Author?
    @State private var authorToDelete: Author?
    @State private var showDeleteConfirmation = false
    @State private var showCreateForm = false
    @State private var errorMessage: String?
    @State private var showError = false

    private func sourceCount(for author: Author) -> Int {
        sources.filter { $0.author?.id == author.id }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Authors")
                    .font(.headline)
                Spacer()
                Button {
                    showCreateForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add author")
                .help("Add author")
                Button("Done") {
                    onDismiss()
                }
                .accessibilityLabel("Close authors panel")
                .help("Close authors panel")
            }
            .padding()

            Divider()

            if authors.isEmpty {
                Text("No authors yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(authors) { author in
                        let count = sourceCount(for: author)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(author.name)
                            Text(count == 1 ? "1 source" : "\(count) sources")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button("Edit...") {
                                authorToEdit = author
                            }
                            Button("Delete", role: .destructive) {
                                authorToDelete = author
                                showDeleteConfirmation = true
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .contentMargins(.bottom, 12, for: .scrollContent)
            }
        }
        .frame(minWidth: 280, minHeight: 320)
        .sheet(isPresented: $showCreateForm) {
            AuthorFormView(
                onSuccess: { showCreateForm = false },
                onCancel: { showCreateForm = false },
                onError: { msg in errorMessage = msg; showError = true }
            )
        }
        .sheet(item: $authorToEdit) { author in
            AuthorFormView(
                existingAuthor: author,
                onSuccess: { authorToEdit = nil },
                onCancel: { authorToEdit = nil },
                onError: { msg in errorMessage = msg; showError = true }
            )
        }
        .confirmationDialog("Delete Author?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let author = authorToDelete {
                    author.deletedAt = Date()
                    try? modelContext.save()
                }
                authorToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                authorToDelete = nil
            }
        } message: {
            if let author = authorToDelete {
                let count = sourceCount(for: author)
                if count > 0 {
                    Text("\(author.name) is used by \(count == 1 ? "1 source" : "\(count) sources"). The author will be removed but those sources will remain.")
                } else {
                    Text("\(author.name) will be removed.")
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage { Text(errorMessage) }
        }
    }
}

#Preview {
    AuthorListView(onDismiss: {})
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}

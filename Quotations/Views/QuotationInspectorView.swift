//
//  QuotationInspectorView.swift
//  Quotations
//

import SwiftData
import SwiftUI

struct QuotationInspectorView: View {
    let quotation: Quotation?
    @Binding var selectedQuotationId: PersistentIdentifier?

    @Environment(\.modelContext) private var modelContext
    @State private var location = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        if let quotation {
            inspectorForm(for: quotation)
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Text("\u{201C}")
                .font(.system(size: 96, design: .serif))
                .foregroundStyle(.quaternary)
                .padding(.bottom, -40)
            Text("Select a quotation to view details")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func inspectorForm(for quotation: Quotation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            inspectorRow(label: "Page number or percentage") {
                TextField("", text: $location)
                    .textFieldStyle(.roundedBorder)
                    .tint(AppColors.highlightColor)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 160, alignment: .trailing)
                    .onChange(of: location) { _, _ in
                        applyLocation(to: quotation)
                    }
            }

            if let source = quotation.source {
                Text("Source Details")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.top, 4)

                readOnlyRow(label: "Format", value: source.format ?? "—")
                readOnlyRow(label: "Date read", value: source.formattedDateRead ?? "—")
            }

            if let updated = quotation.updatedAt {
                Text("Last updated: \(updated, style: .date) \(updated, style: .time)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Quotation", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel("Delete quotation")
            .help("Delete this quotation")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            syncFromQuotation(quotation)
        }
        .onChange(of: selectedQuotationId) { _, _ in
            if let q = self.quotation {
                syncFromQuotation(q)
            }
        }
        .confirmationDialog("Delete this quotation?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                quotation.deletedAt = Date()
                quotation.updatedAt = Date()
                try? modelContext.save()
                selectedQuotationId = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func inspectorRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            content()
        }
    }

    private func readOnlyRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 160, alignment: .trailing)
        }
    }

    private func syncFromQuotation(_ quotation: Quotation) {
        location = quotation.location ?? ""
    }

    private func applyLocation(to quotation: Quotation) {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        quotation.location = trimmed.isEmpty ? nil : trimmed
        quotation.updatedAt = Date()
        try? modelContext.save()
    }
}

#Preview {
    QuotationInspectorView(quotation: nil, selectedQuotationId: .constant(nil))
        .padding()
        .frame(width: 300, height: 400)
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}

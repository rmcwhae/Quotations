//
//  QuotationInspectorView.swift
//  Quotations
//

import SwiftData
import SwiftUI

private let locationDebounceInterval: Duration = .milliseconds(500)

struct QuotationInspectorView: View {
    let quotation: Quotation?
    @Binding var selectedQuotationId: PersistentIdentifier?
    @Binding var showDeleteConfirmation: Bool

    @Environment(\.modelContext) private var modelContext
    @State private var location = ""
    @State private var locationSaveTask: Task<Void, Never>?
    @FocusState private var isLocationFocused: Bool

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
                .foregroundStyle(AppColors.quoteGlyph)
                .accessibilityHidden(true)
                .padding(.bottom, -40)
            Text("Select a quotation to view details")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func inspectorForm(for quotation: Quotation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            locationField(for: quotation)
            sourceDetailsSection(for: quotation)

            if let updated = quotation.updatedAt {
                Text("Last updated: \(updated, style: .date) \(updated, style: .time)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            deleteQuotationButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .id(quotation.persistentModelID)
        .onAppear {
            syncFromQuotation(quotation)
        }
        .onChange(of: selectedQuotationId) { oldId, newId in
            handleQuotationSelectionChange(from: oldId, to: newId)
        }
        .onChange(of: isLocationFocused) { _, focused in
            if !focused {
                locationSaveTask?.cancel()
                applyLocation(to: quotation)
            }
        }
        .onDisappear {
            locationSaveTask?.cancel()
            applyLocation(to: quotation)
        }
    }

    @ViewBuilder
    private func locationField(for quotation: Quotation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            FormFieldRow(label: "Location") {
                TextField("Location", text: $location)
                    .textFieldStyle(.plain)
                    .tint(AppColors.highlightColor)
                    .formInputStyle(maxWidth: 160, isFocused: $isLocationFocused)
                    .accessibilityHint("Page number or percentage")
                    .onChange(of: location) { _, _ in
                        scheduleLocationSave(for: quotation)
                    }
            }

            if isLocationFocused {
                HStack {
                    Spacer(minLength: 8)
                    Text("Page number or percentage")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 160, alignment: .trailing)
                }
            }
        }
    }

    @ViewBuilder
    private func sourceDetailsSection(for quotation: Quotation) -> some View {
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
    }

    private var deleteQuotationButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            Label("Delete Quotation", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .accessibilityLabel("Delete quotation")
        .help("Delete this quotation")
    }

    private func handleQuotationSelectionChange(
        from oldId: PersistentIdentifier?,
        to newId: PersistentIdentifier?
    ) {
        if let oldId, oldId != newId,
           let previous = modelContext.model(for: oldId) as? Quotation {
            locationSaveTask?.cancel()
            applyLocation(to: previous)
        }
        if let newId,
           let resolved = modelContext.model(for: newId) as? Quotation {
            syncFromQuotation(resolved)
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

    private func scheduleLocationSave(for quotation: Quotation) {
        locationSaveTask?.cancel()
        locationSaveTask = Task {
            try? await Task.sleep(for: locationDebounceInterval)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                applyLocation(to: quotation)
            }
        }
    }

    private func applyLocation(to quotation: Quotation) {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let newValue = trimmed.isEmpty ? nil : trimmed
        guard newValue != quotation.location else { return }
        quotation.location = newValue
        quotation.updatedAt = Date()
        try? modelContext.saveAndNotify()
    }
}

#Preview {
    QuotationInspectorView(
        quotation: nil,
        selectedQuotationId: .constant(nil),
        showDeleteConfirmation: .constant(false)
    )
    .padding()
    .frame(width: 300, height: 400)
    .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}

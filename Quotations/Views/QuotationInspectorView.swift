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

    @Environment(\.modelContext) private var modelContext
    @State private var location = ""
    @State private var showDeleteConfirmation = false
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
                .padding(.bottom, -40)
            Text("Select a quotation to view details")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func inspectorForm(for quotation: Quotation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .onChange(of: selectedQuotationId) { _, newId in
            guard let newId,
                  let resolved = modelContext.model(for: newId) as? Quotation else { return }
            syncFromQuotation(resolved)
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
        .confirmationDialog("Remove quotation?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                do {
                    try SoftDelete.quotation(quotation, in: modelContext)
                    NotificationCenter.default.post(name: .quotationsDataDidChange, object: nil)
                } catch {
                    print("Failed to delete quotation: \(error)")
                }
                selectedQuotationId = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This quotation will be removed from your library.")
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
        quotation.location = trimmed.isEmpty ? nil : trimmed
        quotation.updatedAt = Date()
        try? modelContext.save()
        NotificationCenter.default.post(name: .quotationsDataDidChange, object: nil)
    }
}

#Preview {
    QuotationInspectorView(quotation: nil, selectedQuotationId: .constant(nil))
        .padding()
        .frame(width: 300, height: 400)
        .modelContainer(for: [Author.self, Source.self, Quotation.self], inMemory: true)
}

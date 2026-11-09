//
//  FindInPageState.swift
//  Quotations
//

import Foundation
import Observation

@Observable
final class FindInPageState {
    /// What the user has typed in the toolbar Find field.
    var query: String = "" {
        didSet { scheduleApply() }
    }

    /// The query views highlight and filter with. It follows `query` after a short pause so
    /// each keystroke doesn't re-render every list and row; clearing applies at once.
    private(set) var appliedQuery: String = ""

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @ObservationIgnored private var applyTask: Task<Void, Never>?
    @ObservationIgnored private let debounceInterval: Duration = .milliseconds(150)

    private func scheduleApply() {
        applyTask?.cancel()
        guard !trimmedQuery.isEmpty else {
            appliedQuery = query
            return
        }
        applyTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: debounceInterval)
            guard !Task.isCancelled else { return }
            appliedQuery = query
        }
    }
}

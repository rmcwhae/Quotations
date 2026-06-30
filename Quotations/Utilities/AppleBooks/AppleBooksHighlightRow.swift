//
//  AppleBooksHighlightRow.swift
//  Quotations
//

import Foundation

struct AppleBooksHighlightRow: Equatable {
    let annotationUUID: String
    let assetID: String
    let selectedText: String
    let note: String?
    let location: String?
    let bookTitle: String
    let authorName: String?
    /// Seconds since 2001-01-01 (Apple Books / Core Data reference date).
    let dateFinishedSeconds: Double?
}

extension AppleBooksHighlightRow {
    var quotationContent: String {
        let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let note, !note.isEmpty else { return trimmed }
        return "\(trimmed)\n\n— \(note)"
    }

    var dateReadComponents: (month: Int, year: Int)? {
        guard let seconds = dateFinishedSeconds else { return nil }
        let reference = Date(timeIntervalSinceReferenceDate: seconds)
        let components = Calendar.current.dateComponents([.month, .year], from: reference)
        guard let month = components.month, let year = components.year, (1...12).contains(month) else {
            return nil
        }
        return (month, year)
    }
}

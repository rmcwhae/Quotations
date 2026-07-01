//
//  QuotationCSVImportResult.swift
//  Quotations
//

import Foundation

struct QuotationCSVImportResult: Equatable {
    let importedQuotations: Int
    let skippedDuplicates: Int
    let skippedEmpty: Int

    var summaryMessage: String {
        var parts: [String] = []
        if importedQuotations > 0 {
            parts.append("Imported \(importedQuotations) quotation\(importedQuotations == 1 ? "" : "s")")
        } else {
            parts.append("No new quotations were imported")
        }
        if skippedDuplicates > 0 {
            parts.append("skipped \(skippedDuplicates) duplicate\(skippedDuplicates == 1 ? "" : "s")")
        }
        if skippedEmpty > 0 {
            parts.append("skipped \(skippedEmpty) empty row\(skippedEmpty == 1 ? "" : "s")")
        }
        return parts.joined(separator: ", ") + "."
    }
}

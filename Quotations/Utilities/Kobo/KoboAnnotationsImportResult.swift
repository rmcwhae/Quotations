//
//  KoboAnnotationsImportResult.swift
//  Quotations
//

import Foundation

struct KoboAnnotationsImportResult: Equatable {
    let importedAuthors: Int
    let importedSources: Int
    let importedQuotations: Int
    let skippedDuplicates: Int
    let skippedEmpty: Int

    var summaryMessage: String {
        var parts: [String] = []
        if importedQuotations > 0 {
            parts.append("Imported \(importedQuotations) quotation\(importedQuotations == 1 ? "" : "s")")
            if importedSources > 0 {
                parts.append("from \(importedSources) book\(importedSources == 1 ? "" : "s")")
            }
        } else {
            parts.append("No new quotations were imported")
        }
        if skippedDuplicates > 0 {
            parts.append("skipped \(skippedDuplicates) already imported")
        }
        return parts.joined(separator: ", ") + "."
    }
}

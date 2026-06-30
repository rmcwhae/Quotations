//
//  AppleBooksImportResult.swift
//  Quotations
//

import Foundation

struct AppleBooksImportResult: Equatable {
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

enum AppleBooksImportError: LocalizedError, Equatable {
    case databasesNotFound
    case annotationDatabaseUnreadable
    case libraryDatabaseUnreadable
    case userCancelled
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .databasesNotFound:
            return "Apple Books databases could not be found. Choose the annotation database when prompted."
        case .annotationDatabaseUnreadable:
            return "The Apple Books annotation database could not be read."
        case .libraryDatabaseUnreadable:
            return "The Apple Books library database could not be read."
        case .userCancelled:
            return "Import was cancelled."
        case .importFailed(let message):
            return message
        }
    }
}

//
//  QuotationCSVImportError.swift
//  Quotations
//

import Foundation

enum QuotationCSVImportError: LocalizedError, Equatable {
    case emptyFile
    case invalidFormat(String)
    case readFailed(String)
    case sourceDeleted

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty."
        case .invalidFormat(let message):
            return message
        case .readFailed(let message):
            return "Could not read the CSV file: \(message)"
        case .sourceDeleted:
            return "The selected source is no longer available."
        }
    }
}

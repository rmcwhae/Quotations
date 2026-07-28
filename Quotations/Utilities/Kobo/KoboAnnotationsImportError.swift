//
//  KoboAnnotationsImportError.swift
//  Quotations
//

import Foundation

enum KoboAnnotationsImportError: LocalizedError, Equatable {
    case emptyFile
    case invalidFormat(String)
    case readFailed(String)
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The Kobo annotations file is empty."
        case .invalidFormat(let message):
            return message
        case .readFailed(let message):
            return "Could not read the Kobo annotations file: \(message)"
        case .importFailed(let message):
            return message
        }
    }
}

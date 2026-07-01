//
//  NewSourceSheetSession.swift
//  Quotations
//

import Foundation

/// Stable identity for the new-source sheet so form state survives parent re-renders.
struct NewSourceSheetSession: Identifiable {
    let id = UUID()
}

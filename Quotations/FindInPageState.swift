//
//  FindInPageState.swift
//  Quotations
//

import Foundation
import Observation

@Observable
final class FindInPageState {
    var query: String = ""

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

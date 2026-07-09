//
//  ExploreScope.swift
//  Quotations
//

import Foundation

enum ExploreVisualizationMode: String, CaseIterable, Identifiable {
    case wordBubbles
    case semanticClusters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wordBubbles: "Word Cloud"
        case .semanticClusters: "Semantic Map"
        }
    }
}

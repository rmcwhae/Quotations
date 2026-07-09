//
//  SemanticClusterMapView.swift
//  Quotations
//

import SwiftUI
import SwiftData

struct SemanticClusterMapView: View {
    let result: SemanticClusterResult
    var selectedQuotationId: PersistentIdentifier?
    var onSelectQuotation: (PersistentIdentifier, PersistentIdentifier?) -> Void

    private let palette: [Color] = [
        .blue, .orange, .green, .purple, .pink, .teal, .indigo, .brown
    ]

    var body: some View {
        GeometryReader { geometry in
            let normalized = normalizedPoints(in: geometry.size)
            ZStack(alignment: .topLeading) {
                ForEach(result.points) { point in
                    if let layout = normalized[point.quotationId] {
                        Button {
                            onSelectQuotation(point.quotationId, point.sourceId)
                        } label: {
                            Circle()
                                .fill(color(for: point.clusterIndex).opacity(point.quotationId == selectedQuotationId ? 0.95 : 0.65))
                                .overlay {
                                    Circle()
                                        .strokeBorder(
                                            point.quotationId == selectedQuotationId ? Color.primary : Color.clear,
                                            lineWidth: 2
                                        )
                                }
                                .frame(width: 12, height: 12)
                        }
                        .buttonStyle(.plain)
                        .position(layout)
                        .help(point.clusterLabel)
                    }
                }
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [PersistentIdentifier: CGPoint] {
        guard !result.points.isEmpty else { return [:] }

        let xs = result.points.map(\.position.x)
        let ys = result.points.map(\.position.y)
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 1
        let spanX = max(maxX - minX, 0.001)
        let spanY = max(maxY - minY, 0.001)
        let padding: CGFloat = 24

        var map: [PersistentIdentifier: CGPoint] = [:]
        for point in result.points {
            let nx = padding + (CGFloat(point.position.x - minX) / CGFloat(spanX)) * (size.width - padding * 2)
            let ny = padding + (CGFloat(point.position.y - minY) / CGFloat(spanY)) * (size.height - padding * 2)
            map[point.quotationId] = CGPoint(x: nx, y: ny)
        }
        return map
    }

    private func color(for cluster: Int) -> Color {
        palette[cluster % palette.count]
    }
}

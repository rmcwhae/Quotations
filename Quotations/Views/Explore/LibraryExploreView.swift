//
//  LibraryExploreView.swift
//  Quotations
//

import SwiftData
import SwiftUI

struct LibraryExploreView: View {
    let quotations: [Quotation]
    @Bindable var exploreState: ExploreState
    @Binding var selectedQuotationId: PersistentIdentifier?
    @Binding var selectedSourceIdBinding: PersistentIdentifier?
    var onWordSelected: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            controls

            if exploreState.isAnalyzing {
                ProgressView("Analyzing library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = exploreState.statusMessage,
                      exploreState.wordFrequencies.isEmpty,
                      exploreState.semanticClusters == nil {
                Text(message)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                visualization
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .onAppear { refresh() }
        .onChange(of: exploreState.minimumWordLength) { _, _ in refresh() }
        .onChange(of: quotations.count) { _, _ in refresh() }
        .onReceive(NotificationCenter.default.publisher(for: .quotationsDataDidChange)) { _ in
            refresh()
        }
    }

    private var controls: some View {
        HStack(alignment: .center, spacing: 12) {
            Picker("Visualization", selection: $exploreState.visualizationMode) {
                ForEach(ExploreVisualizationMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .layoutPriority(1)

            Stepper(
                value: $exploreState.minimumWordLength,
                in: 2...8
            ) {
                Text("Minimum characters in word: \(exploreState.minimumWordLength)")
            }
            .fixedSize()
        }
    }

    @ViewBuilder
    private var visualization: some View {
        switch exploreState.visualizationMode {
        case .wordBubbles:
            if exploreState.wordFrequencies.isEmpty {
                emptyMessage("No word frequencies to display.")
            } else {
                ExploreZoomableContainer {
                    WordBubbleChartView(entries: exploreState.wordFrequencies, onSelectWord: onWordSelected)
                }
            }
        case .semanticClusters:
            if let clusters = exploreState.semanticClusters {
                VStack(alignment: .leading, spacing: 8) {
                    clusterLegend(clusters)
                    ExploreZoomableContainer {
                        SemanticClusterMapView(
                            result: clusters,
                            selectedQuotationId: selectedQuotationId,
                            onSelectQuotation: selectQuotation
                        )
                    }
                }
            } else {
                emptyMessage("Semantic maps need at least two indexed quotations.")
            }
        }
    }

    private func clusterLegend(_ clusters: SemanticClusterResult) -> some View {
        let labels = Dictionary(grouping: clusters.points, by: \.clusterIndex)
            .sorted { $0.key < $1.key }
            .map { index, points in
                points.first?.clusterLabel ?? "Theme \(index + 1)"
            }

        return Text(labels.joined(separator: " · "))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    private func emptyMessage(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func refresh() {
        exploreState.refresh(quotations: quotations)
    }

    private func selectQuotation(_ quotationId: PersistentIdentifier, sourceId: PersistentIdentifier?) {
        selectedQuotationId = quotationId
        if let sourceId {
            selectedSourceIdBinding = sourceId
        }
    }
}

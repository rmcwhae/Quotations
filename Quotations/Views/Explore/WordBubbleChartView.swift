//
//  WordBubbleChartView.swift
//  Quotations
//

import SwiftUI

struct WordBubbleChartView: View {
    let entries: [WordFrequencyEntry]
    var onSelectWord: (String) -> Void

    private struct BubbleLayout: Identifiable {
        let entry: WordFrequencyEntry
        let center: CGPoint
        let radius: CGFloat

        var id: String { entry.id }
    }

    private struct LayoutKey: Equatable {
        let entries: [WordFrequencyEntry]
        let width: Int
        let height: Int

        init(entries: [WordFrequencyEntry], size: CGSize) {
            self.entries = entries
            width = Int(size.width.rounded())
            height = Int(size.height.rounded())
        }
    }

    /// The force-directed layout is expensive (hundreds of iterations), so it's cached
    /// and only recomputed when the entries or the rounded container size change.
    @State private var layouts: [BubbleLayout] = []
    @State private var layoutKey: LayoutKey?

    var body: some View {
        GeometryReader { geometry in
            let key = LayoutKey(entries: entries, size: geometry.size)
            ZStack {
                ForEach(layouts) { bubble in
                    Button {
                        onSelectWord(bubble.entry.word)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AppColors.highlightColor.opacity(0.22))
                            Circle()
                                .strokeBorder(AppColors.highlightColor.opacity(0.55), lineWidth: 1)
                            Text(bubble.entry.word)
                                .font(.system(size: fontSize(for: bubble.entry.count), design: .serif))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.6)
                                .multilineTextAlignment(.center)
                                .padding(8)
                        }
                        .clipShape(Circle())
                        .frame(width: bubble.radius * 2, height: bubble.radius * 2)
                    }
                    .buttonStyle(.plain)
                    .position(bubble.center)
                    .help("\(bubble.entry.word): \(bubble.entry.count)")
                }
            }
            .onAppear { updateLayout(for: key, size: geometry.size) }
            .onChange(of: key) { _, newKey in updateLayout(for: newKey, size: geometry.size) }
        }
    }

    private func updateLayout(for key: LayoutKey, size: CGSize) {
        guard key != layoutKey else { return }
        layoutKey = key
        layouts = bubbleLayout(in: size)
    }

    private func bubbleLayout(in size: CGSize) -> [BubbleLayout] {
        guard !entries.isEmpty, size.width > 0, size.height > 0 else { return [] }

        let maxCount = entries.map(\.count).max() ?? 1
        let radii = entries.map { entry in
            (
                id: entry.id,
                radius: ForceDirectedBubbleLayout.radius(for: entry.count, maxCount: maxCount)
            )
        }

        let positions = ForceDirectedBubbleLayout.layout(radii: radii, in: size)

        return entries.compactMap { entry in
            guard let center = positions[entry.id] else { return nil }
            let radius = ForceDirectedBubbleLayout.radius(for: entry.count, maxCount: maxCount)
            return BubbleLayout(entry: entry, center: center, radius: radius)
        }
    }

    private func fontSize(for count: Int) -> CGFloat {
        let maxCount = entries.map(\.count).max() ?? 1
        let ratio = CGFloat(count) / CGFloat(maxCount)
        return 11 + ratio * 7
    }
}

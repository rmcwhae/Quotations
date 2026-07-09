//
//  ExploreZoomableContainer.swift
//  Quotations
//

import SwiftUI

struct ExploreZoomableContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        content()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .animation(.easeOut(duration: 0.15), value: scale)
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = min(3, max(0.5, lastScale * value.magnification))
            }
            .onEnded { _ in
                lastScale = scale
            }
    }
}

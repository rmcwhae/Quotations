//
//  ForceDirectedBubbleLayoutTests.swift
//  QuotationsTests
//

import CoreGraphics
import XCTest
@testable import Quotations

final class ForceDirectedBubbleLayoutTests: XCTestCase {
    func testLayoutSeparatesOverlappingCircles() {
        let radii = [
            (id: "large", radius: CGFloat(60)),
            (id: "medium", radius: CGFloat(40)),
            (id: "small", radius: CGFloat(28)),
            (id: "tiny", radius: CGFloat(24))
        ]
        let size = CGSize(width: 400, height: 400)
        let positions = ForceDirectedBubbleLayout.layout(radii: radii, in: size)

        XCTAssertEqual(positions.count, radii.count)

        for firstIndex in 0..<radii.count {
            for secondIndex in (firstIndex + 1)..<radii.count {
                let firstID = radii[firstIndex].id
                let secondID = radii[secondIndex].id
                guard let first = positions[firstID], let second = positions[secondID] else {
                    return XCTFail("Missing layout position")
                }
                let distance = hypot(first.x - second.x, first.y - second.y)
                let minimum = radii[firstIndex].radius + radii[secondIndex].radius
                XCTAssertGreaterThanOrEqual(distance, minimum - 0.01, "Bubbles \(firstID) and \(secondID) overlap")
            }
        }
    }

    func testLayoutSeparatesManyBubbles() {
        let radii = (0..<24).map { index in
            (id: "word-\(index)", radius: CGFloat(28 + (index % 5) * 8))
        }
        let positions = ForceDirectedBubbleLayout.layout(radii: radii, in: CGSize(width: 500, height: 500))
        XCTAssertEqual(positions.count, radii.count)

        for firstIndex in 0..<radii.count {
            for secondIndex in (firstIndex + 1)..<radii.count {
                guard let first = positions[radii[firstIndex].id], let second = positions[radii[secondIndex].id] else {
                    return XCTFail("Missing position")
                }
                let distance = hypot(first.x - second.x, first.y - second.y)
                let minimum = radii[firstIndex].radius + radii[secondIndex].radius
                XCTAssertGreaterThanOrEqual(distance, minimum - 0.01)
            }
        }
    }
}

//
//  ForceDirectedBubbleLayout.swift
//  Quotations
//

import CoreGraphics
import Foundation

struct ForceBubbleNode: Identifiable {
    let id: String
    let radius: CGFloat
    var position: CGPoint
    var velocity: CGVector = .zero
}

enum ForceDirectedBubbleLayout {
    private static let padding: CGFloat = 8
    private static let centerStrength: CGFloat = 0.04
    private static let collisionStrength: CGFloat = 1.2
    private static let velocityDecay: CGFloat = 0.55
    private static let maxIterations = 400
    private static let overlapResolutionPasses = 96

    static func layout(
        radii: [(id: String, radius: CGFloat)],
        in size: CGSize
    ) -> [String: CGPoint] {
        guard !radii.isEmpty else { return [:] }

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        var nodes = initialNodes(from: radii, center: center)
        var alpha: CGFloat = 1

        for _ in 0..<maxIterations {
            applyCenterForce(to: &nodes, center: center, alpha: alpha)
            applyCollisionForce(to: &nodes, alpha: alpha)

            for index in nodes.indices {
                nodes[index].velocity.dx *= velocityDecay
                nodes[index].velocity.dy *= velocityDecay
                nodes[index].position.x += nodes[index].velocity.dx
                nodes[index].position.y += nodes[index].velocity.dy
            }

            alpha *= 0.98
            if alpha < 0.01 { break }
        }

        resolveOverlaps(&nodes)
        fitNodes(&nodes, in: size)
        resolveOverlaps(&nodes)
        return Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.position) })
    }

    static func radius(
        for count: Int,
        maxCount: Int,
        minRadius: CGFloat = 28,
        maxRadius: CGFloat = 72
    ) -> CGFloat {
        guard maxCount > 0 else { return minRadius }
        return minRadius + (maxRadius - minRadius) * CGFloat(count) / CGFloat(maxCount)
    }

    private static func initialNodes(
        from radii: [(id: String, radius: CGFloat)],
        center: CGPoint
    ) -> [ForceBubbleNode] {
        let sorted = radii.sorted { $0.radius > $1.radius }
        return sorted.enumerated().map { index, item in
            let angle = CGFloat(index) * 0.95
            let distance = item.radius + CGFloat(index) * (item.radius * 0.15 + 6)
            return ForceBubbleNode(
                id: item.id,
                radius: item.radius,
                position: CGPoint(
                    x: center.x + cos(angle) * distance,
                    y: center.y + sin(angle) * distance
                )
            )
        }
    }

    private static func applyCenterForce(
        to nodes: inout [ForceBubbleNode],
        center: CGPoint,
        alpha: CGFloat
    ) {
        for index in nodes.indices {
            let dx = center.x - nodes[index].position.x
            let dy = center.y - nodes[index].position.y
            nodes[index].velocity.dx += dx * centerStrength * alpha
            nodes[index].velocity.dy += dy * centerStrength * alpha
        }
    }

    private static func applyCollisionForce(to nodes: inout [ForceBubbleNode], alpha: CGFloat) {
        guard nodes.count > 1 else { return }

        for first in nodes.indices {
            for second in (first + 1)..<nodes.count {
                var dx = nodes[second].position.x - nodes[first].position.x
                var dy = nodes[second].position.y - nodes[first].position.y
                var distance = hypot(dx, dy)

                let minimumDistance = nodes[first].radius + nodes[second].radius + padding
                if distance == 0 {
                    dx = CGFloat.random(in: -1...1)
                    dy = CGFloat.random(in: -1...1)
                    distance = 0.01
                }

                if distance < minimumDistance {
                    let overlap = (minimumDistance - distance) / distance
                    let force = overlap * collisionStrength * alpha
                    let offsetX = dx * force * 0.5
                    let offsetY = dy * force * 0.5

                    nodes[first].velocity.dx -= offsetX
                    nodes[first].velocity.dy -= offsetY
                    nodes[second].velocity.dx += offsetX
                    nodes[second].velocity.dy += offsetY
                }
            }
        }
    }

    /// Directly separates overlapping circles until none remain.
    private static func resolveOverlaps(_ nodes: inout [ForceBubbleNode]) {
        guard nodes.count > 1 else { return }

        for _ in 0..<overlapResolutionPasses {
            var moved = false

            for first in nodes.indices {
                for second in (first + 1)..<nodes.count {
                    var dx = nodes[second].position.x - nodes[first].position.x
                    var dy = nodes[second].position.y - nodes[first].position.y
                    var distance = hypot(dx, dy)
                    let minimumDistance = nodes[first].radius + nodes[second].radius + padding

                    if distance < minimumDistance {
                        if distance < 0.001 {
                            dx = 1
                            dy = 0
                            distance = 0.001
                        }

                        let separation = (minimumDistance - distance) / 2
                        let normalX = dx / distance
                        let normalY = dy / distance

                        nodes[first].position.x -= normalX * separation
                        nodes[first].position.y -= normalY * separation
                        nodes[second].position.x += normalX * separation
                        nodes[second].position.y += normalY * separation
                        moved = true
                    }
                }
            }

            if !moved { break }
        }
    }

    private static func fitNodes(_ nodes: inout [ForceBubbleNode], in size: CGSize) {
        guard let first = nodes.first else { return }

        var minX = first.position.x - first.radius
        var maxX = first.position.x + first.radius
        var minY = first.position.y - first.radius
        var maxY = first.position.y + first.radius

        for node in nodes.dropFirst() {
            minX = min(minX, node.position.x - node.radius)
            maxX = max(maxX, node.position.x + node.radius)
            minY = min(minY, node.position.y - node.radius)
            maxY = max(maxY, node.position.y + node.radius)
        }

        let contentCenter = CGPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
        let viewCenter = CGPoint(x: size.width / 2, y: size.height / 2)
        let offset = CGPoint(x: viewCenter.x - contentCenter.x, y: viewCenter.y - contentCenter.y)

        for index in nodes.indices {
            nodes[index].position.x += offset.x
            nodes[index].position.y += offset.y
        }
    }
}

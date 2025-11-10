import SwiftUI
import Vision

struct RectangleOverlay: Shape {
    let rect: VNRectangleObservation

    func path(in frame: CGRect) -> Path {
        var path = Path()

        // Vision coordinates are normalized (0–1),
        // so we need to map them to screen coordinates.
        let topLeft = CGPoint(x: rect.topLeft.x * frame.width,
                              y: (1 - rect.topLeft.y) * frame.height)
        let topRight = CGPoint(x: rect.topRight.x * frame.width,
                               y: (1 - rect.topRight.y) * frame.height)
        let bottomRight = CGPoint(x: rect.bottomRight.x * frame.width,
                                  y: (1 - rect.bottomRight.y) * frame.height)
        let bottomLeft = CGPoint(x: rect.bottomLeft.x * frame.width,
                                 y: (1 - rect.bottomLeft.y) * frame.height)

        // Connect all corners to draw a rectangle
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()

        return path
    }
}


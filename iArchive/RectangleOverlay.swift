import SwiftUI
import Vision
import AVFoundation

struct RectangleOverlay: Shape {
    let rect: VNRectangleObservation?
    var normalizedPoints: [CGPoint]?
    var previewLayer: AVCaptureVideoPreviewLayer?

    func path(in frame: CGRect) -> Path {
        var path = Path()

        // Convert Vision normalized points to preview layer coordinates.
        func convert(_ p: CGPoint) -> CGPoint {
            let poi = CGPoint(x: p.x, y: 1 - p.y) // flip y to top-left origin
            if let layer = previewLayer {
                return layer.layerPointConverted(fromCaptureDevicePoint: poi)
            } else {
                // Fallback: naive mapping to the frame if layer unavailable
                return CGPoint(x: poi.x * frame.width, y: poi.y * frame.height)
            }
        }

        // Choose sources: smoothed points or raw rectangle observation
        let points: [CGPoint]
        if let normalizedPoints = normalizedPoints, normalizedPoints.count == 4 {
            points = normalizedPoints
        } else if let rect = rect {
            points = [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]
        } else {
            return path
        }

        let topLeft = convert(points[0])
        let topRight = convert(points[1])
        let bottomRight = convert(points[2])
        let bottomLeft = convert(points[3])

        // Connect all corners to draw a rectangle
        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()

        return path
    }
}


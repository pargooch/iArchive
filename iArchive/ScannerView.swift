import SwiftUI
import Vision

struct ScannerView: View {
    @StateObject private var camera = CameraManager()

    var body: some View {
        ZStack {
            // Live camera feed
            CameraPreview(manager: camera)
                .edgesIgnoringSafeArea(.all)

            // Overlay rectangle when a document is detected
            if let points = camera.smoothedPoints {
                RectangleOverlay(rect: nil, normalizedPoints: points, previewLayer: camera.previewLayer)
                    .stroke(Color.yellow, lineWidth: 3)
                    .animation(.easeInOut(duration: 0.2), value: points)
            } else if let rect = camera.lastDetectedRect {
                RectangleOverlay(rect: rect, normalizedPoints: nil, previewLayer: camera.previewLayer)
                    .stroke(Color.yellow, lineWidth: 3)
                    .animation(.easeInOut(duration: 0.2), value: rect.boundingBox)
            }
        }
        .onAppear {
            camera.startSession()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
}


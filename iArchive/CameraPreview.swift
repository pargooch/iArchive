import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var manager: CameraManager

    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = manager.session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        // Expose preview layer for coordinate conversion
        DispatchQueue.main.async { [weak manager] in
            manager?.previewLayer = view.videoPreviewLayer
            // Keep preview orientation in sync
            view.videoPreviewLayer.connection?.videoOrientation = manager?.currentVideoOrientation() ?? .portrait
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Update orientation on changes
        uiView.videoPreviewLayer.connection?.videoOrientation = manager.currentVideoOrientation()
    }
}


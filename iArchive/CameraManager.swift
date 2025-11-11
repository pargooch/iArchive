import Foundation
import AVFoundation
import Vision
import Combine
import CoreImage
import UIKit

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutput = AVCaptureVideoDataOutput()

    // Vision
    private var request: VNDetectRectanglesRequest?
    private let visionQueue = DispatchQueue(label: "vision.queue")

    // Published property for the latest detected rectangle
    @Published var lastDetectedRect: VNRectangleObservation?
    // Expose preview layer for coordinate conversions
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    // Smoothed normalized points for stable overlay
    @Published var smoothedPoints: [CGPoint]?
    private var lastSmoothedPoints: [CGPoint]?
    private let smoothingAlpha: CGFloat = 0.65
    private(set) var cameraPosition: AVCaptureDevice.Position = .unspecified

    override init() {
        super.init()
        configureSession()
        configureVision()
    }

    // MARK: - Camera Configuration
    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Select the back camera
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        cameraPosition = device.position

        // Improve capture quality: continuous autofocus and exposure
        if device.isFocusModeSupported(.continuousAutoFocus) || device.isExposureModeSupported(.continuousAutoExposure) || device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isAutoFocusRangeRestrictionSupported {
                    device.autoFocusRangeRestriction = .none
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                device.isSubjectAreaChangeMonitoringEnabled = true
                device.unlockForConfiguration()
            } catch {
                // Ignore configuration errors
            }
        }

        // Set up video output for frame-by-frame processing
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Attempt to align connection orientation with device orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = currentVideoOrientation()
        }

        session.commitConfiguration()
    }

    // MARK: - Vision Rectangle Detection Configuration
    private func configureVision() {
        // Set up Vision request to detect rectangles
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let results = request.results as? [VNRectangleObservation],
               !results.isEmpty,
               let best = results.max(by: { lhs, rhs in
                   let lhsScore = self.rectScore(lhs)
                   let rhsScore = self.rectScore(rhs)
                   return lhsScore < rhsScore
               }) {
                // Pass the detected rectangle to SwiftUI
                DispatchQueue.main.async {
                    self.lastDetectedRect = best
                    // Smooth points frame-to-frame
                    let current = [best.topLeft, best.topRight, best.bottomRight, best.bottomLeft]
                    var blended = current
                    if let prev = self.lastSmoothedPoints, prev.count == 4 {
                        let a = self.smoothingAlpha
                        blended = zip(prev, current).map { (p, c) in
                            CGPoint(x: p.x * (1 - a) + c.x * a,
                                    y: p.y * (1 - a) + c.y * a)
                        }
                    }
                    self.smoothedPoints = blended
                    self.lastSmoothedPoints = blended
                }
            } else {
                DispatchQueue.main.async {
                    self.lastDetectedRect = nil
                    self.smoothedPoints = nil
                    self.lastSmoothedPoints = nil
                }
            }
        }

        // Vision rectangle detection parameters
        request.maximumObservations = 5        // detect several candidates
        request.minimumConfidence = 0.6        // allow more candidates, filter later
        request.minimumAspectRatio = 0.3       // ignore very tall/narrow shapes
        request.quadratureTolerance = 30       // allow perspective warp on handheld
        if #available(iOS 15.0, *) {
            request.minimumSize = 0.15         // allow medium-sized documents
        }
        // Focus detection in the center of the frame
        request.regionOfInterest = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
        self.request = request
    }

    // MARK: - Control Session
    func startSession() {
        sessionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    // MARK: - Orientation Helpers
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft: return .landscapeRight // device left = camera right for back camera
        case .landscapeRight: return .landscapeLeft
        case .portraitUpsideDown: return .portraitUpsideDown
        default: return .portrait
        }
    }

    private func currentImageOrientation() -> CGImagePropertyOrientation {
        // Map device orientation to EXIF orientation for Vision
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            return .left
        case .landscapeLeft:
            return .up
        case .landscapeRight:
            return .down
        case .faceDown:
            return .down
        case .faceUp:
            return .up
        default:
            return .right
        }
    }
}

// MARK: - Capture Output Delegate (Vision Processing)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Send each camera frame to Vision
        guard let request = self.request else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Use the actual capture connection orientation to inform Vision
        let exif = exifOrientation(for: connection.videoOrientation, cameraPosition: cameraPosition)
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: exif,
                                            options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Scoring helper
extension CameraManager {
    private func rectScore(_ rect: VNRectangleObservation) -> CGFloat {
        // Combine size (area) and confidence to prefer large, clear documents
        let points = [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft]
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else { return 0 }
        let area = (maxX - minX) * (maxY - minY)
        return area * CGFloat(rect.confidence)
    }
}

// MARK: - EXIF Orientation mapping
extension CameraManager {
    fileprivate func exifOrientation(for videoOrientation: AVCaptureVideoOrientation,
                                     cameraPosition: AVCaptureDevice.Position) -> CGImagePropertyOrientation {
        switch videoOrientation {
        case .portrait:
            return cameraPosition == .front ? .leftMirrored : .right
        case .portraitUpsideDown:
            return cameraPosition == .front ? .rightMirrored : .left
        case .landscapeLeft:
            return cameraPosition == .front ? .downMirrored : .up
        case .landscapeRight:
            return cameraPosition == .front ? .upMirrored : .down
        @unknown default:
            return .right
        }
    }
}


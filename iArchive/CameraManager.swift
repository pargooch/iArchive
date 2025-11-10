import Foundation
import AVFoundation
import Vision
import Combine
import CoreImage

final class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutput = AVCaptureVideoDataOutput()

    // Vision
    private var request: VNDetectRectanglesRequest?
    private let visionQueue = DispatchQueue(label: "vision.queue")

    // Published property for the latest detected rectangle
    @Published var lastDetectedRect: VNRectangleObservation?

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

        // Set up video output for frame-by-frame processing
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    // MARK: - Vision Rectangle Detection Configuration
    private func configureVision() {
        // Set up Vision request to detect rectangles
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let results = request.results as? [VNRectangleObservation],
               let first = results.first {
                // Pass the detected rectangle to SwiftUI
                DispatchQueue.main.async {
                    self.lastDetectedRect = first
                }
            } else {
                DispatchQueue.main.async {
                    self.lastDetectedRect = nil
                }
            }
        }

        // Vision rectangle detection parameters
        request.maximumObservations = 1        // detect only one rectangle
        request.minimumConfidence = 0.7        // confidence threshold
        request.minimumAspectRatio = 0.3       // ignore very tall/narrow shapes
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
}

// MARK: - Capture Output Delegate (Vision Processing)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        // Send each camera frame to Vision
        guard let request = self.request else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                            orientation: .up,
                                            options: [:])
        try? handler.perform([request])
    }
}


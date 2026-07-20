import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - Camera Manager
/// Manages the AVFoundation camera capture session, frame extraction,
/// and auto-capture when a stable, sharp board image is detected.

@MainActor
public final class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published State
    
    /// Whether the camera is currently active.
    @Published public var isRunning = false
    
    /// The most recently captured frame as UIImage.
    @Published public var currentFrame: UIImage?
    
    /// Whether a stable, sharp board image has been auto-captured.
    @Published public var hasCaptured = false
    
    /// The auto-captured high-quality frame.
    @Published public var capturedFrame: UIImage?
    
    /// Status message for the user.
    @Published public var statusMessage = "Point camera at the board"
    
    /// Whether the board is currently detected in the frame.
    @Published public var isBoardDetected = false
    
    // MARK: - AVFoundation
    
    public let captureSession = AVCaptureSession()
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "com.carrom.camera.session")
    private let processingQueue = DispatchQueue(label: "com.carrom.camera.processing")
    
    // MARK: - Stability Detection
    
    private var stableFrameCounter = 0
    private var previousFrameCenterIntensity: Double = 0
    private let frameAnalyzer = FrameAnalyzer()
    
    // MARK: - Callback
    
    /// Called when a high-quality frame is auto-captured.
    public var onFrameCaptured: ((UIImage) -> Void)?
    
    // MARK: - Lifecycle
    
    public override init() {
        super.init()
    }
    
    /// Configure and start the camera capture session.
    public func startSession() {
        guard !isRunning else { return }
        
        sessionQueue.async { [weak self] in
            self?.configureSession()
            self?.captureSession.startRunning()
            
            Task { @MainActor in
                self?.isRunning = true
                self?.statusMessage = "Point camera at the board"
            }
        }
    }
    
    /// Stop the camera capture session.
    public func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            
            Task { @MainActor in
                self?.isRunning = false
            }
        }
    }
    
    /// Reset capture state for a new scan.
    public func resetCapture() {
        hasCaptured = false
        capturedFrame = nil
        stableFrameCounter = 0
        statusMessage = "Point camera at the board"
    }
    
    // MARK: - Session Configuration
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080
        
        // Camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            Log.camera.error("Failed to access back camera")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Configure camera for best quality
        try? camera.lockForConfiguration()
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            camera.focusMode = .continuousAutoFocus
        }
        if camera.isExposureModeSupported(.continuousAutoExposure) {
            camera.exposureMode = .continuousAutoExposure
        }
        camera.unlockForConfiguration()
        
        // Video output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: processingQueue)
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            self.videoOutput = output
        }
        
        captureSession.commitConfiguration()
        Log.camera.info("Camera session configured")
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    nonisolated public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        
        Task { @MainActor [weak self] in
            guard let self = self, !self.hasCaptured else { return }
            
            self.currentFrame = image
            self.processFrame(image)
        }
    }
}

// MARK: - Frame Processing

extension CameraManager {
    
    /// Process a frame for quality and stability.
    private func processFrame(_ image: UIImage) {
        // 1. Check blur
        let blurScore = frameAnalyzer.blurScore(image)
        guard blurScore >= AppConfig.blurThreshold else {
            statusMessage = "Hold steady — image is blurry"
            stableFrameCounter = 0
            return
        }
        
        // 2. Check stability (frame-to-frame difference)
        let currentIntensity = frameAnalyzer.centerIntensity(image)
        let displacement = abs(currentIntensity - previousFrameCenterIntensity)
        previousFrameCenterIntensity = currentIntensity
        
        if displacement < AppConfig.stabilityDisplacementThreshold {
            stableFrameCounter += 1
        } else {
            stableFrameCounter = 0
        }
        
        // 3. Update status
        if stableFrameCounter < AppConfig.stableFrameCount {
            statusMessage = "Hold steady... (\(stableFrameCounter)/\(AppConfig.stableFrameCount))"
            isBoardDetected = true
        }
        
        // 4. Auto-capture when stable
        if stableFrameCounter >= AppConfig.stableFrameCount {
            capturedFrame = image
            hasCaptured = true
            statusMessage = "Board captured! Analyzing..."
            stableFrameCounter = 0
            
            Log.camera.info("Auto-captured stable frame (blur=\(blurScore, format: .fixed(precision: 1)))")
            
            onFrameCaptured?(image)
        }
    }
}

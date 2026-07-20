import SwiftUI
import AVFoundation

// MARK: - Camera Preview
/// SwiftUI view that wraps AVCaptureVideoPreviewLayer for live camera feed display.

public struct CameraPreview: UIViewRepresentable {
    
    let session: AVCaptureSession
    
    public init(session: AVCaptureSession) {
        self.session = session
    }
    
    public func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }
    
    public func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.session = session
    }
}

// MARK: - UIKit Preview View

public class CameraPreviewUIView: UIView {
    
    var session: AVCaptureSession? {
        didSet {
            previewLayer.session = session
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }
    
    private func setupPreviewLayer() {
        previewLayer.videoGravity = .resizeAspectFill
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

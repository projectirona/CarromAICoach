import SwiftUI

// MARK: - Scan View
/// Camera scanning view with live preview and status indicators.

struct ScanView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: appState.cameraManager.captureSession)
                .ignoresSafeArea()
            
            // Overlay
            VStack {
                // Top bar: player color
                topBar
                
                Spacer()
                
                // Status indicator
                statusIndicator
                    .padding(.bottom, 40)
            }
            
            // Board frame guide
            boardGuide
            
            // Loading overlay when analyzing
            if appState.isAnalyzing {
                analyzingOverlay
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Player color indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.playerColor == .black ?
                          Color(white: 0.15) : Color(white: 0.95))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Text(appState.playerColor?.rawValue ?? "")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            
            Spacer()
            
            // Turn counter
            if let match = appState.matchState {
                Text("Turn \(match.currentTurn)")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Board Guide
    
    private var boardGuide: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height) * 0.8
            
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    appState.cameraManager.isBoardDetected ?
                    Color.green.opacity(0.6) : Color.white.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                )
                .frame(width: size, height: size)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .animation(.easeInOut(duration: 0.3), value: appState.cameraManager.isBoardDetected)
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        HStack(spacing: 10) {
            if appState.cameraManager.hasCaptured {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(0.8)
            }
            
            Text(appState.cameraManager.statusMessage)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Analyzing Overlay
    
    private var analyzingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.orange)
                    .scaleEffect(1.5)
                
                Text("Analyzing board...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Finding the best shot")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

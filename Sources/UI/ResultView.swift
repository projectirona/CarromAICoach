import SwiftUI

// MARK: - Result View
/// Displays the AI recommendation with the board overlay and shot info.

struct ResultView: View {
    
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar
            
            // Board image with overlay
            boardSection
            
            // Recommendation card
            if let recommendation = appState.currentRecommendation {
                recommendationCard(recommendation)
            }
            
            // Action buttons
            actionButtons
        }
        .background(Color.black)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Player color
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.playerColor == .black ?
                          Color(white: 0.15) : Color(white: 0.95))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Text(appState.playerColor?.rawValue ?? "")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Turn
            if let match = appState.matchState {
                Text("Turn \(match.currentTurn)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Analysis time
            if let recommendation = appState.currentRecommendation {
                Text("\(String(format: "%.2f", recommendation.analysisTime))s")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black)
    }
    
    // MARK: - Board Section
    
    private var boardSection: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            
            ZStack {
                // Captured board image
                if let image = appState.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size, height: size)
                }
                
                // Shot overlay
                if let recommendation = appState.currentRecommendation {
                    BoardOverlay(
                        recommendation: recommendation,
                        size: CGSize(width: size, height: size)
                    )
                    .frame(width: size, height: size)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
    }
    
    // MARK: - Recommendation Card
    
    private func recommendationCard(_ recommendation: Recommendation) -> some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                ProbabilityBadge(probability: recommendation.probability)
                
                Spacer()
                
                PowerIndicator(power: recommendation.powerDisplay)
            }
            
            // Shot info
            ShotInfoCard(recommendation: recommendation)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // New Match button
            Button {
                appState.newMatch()
            } label: {
                Label("New Match", systemImage: "arrow.counterclockwise")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.08))
                    )
            }
            
            // Scan Again button (primary)
            Button {
                appState.scanAgain()
            } label: {
                Label("Next Shot", systemImage: "camera.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

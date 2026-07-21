import SwiftUI
import Vision

// MARK: - Live AR Overlay
/// Renders the inverse homography of the recommended shot directly over the live camera feed.

struct LiveAROverlay: View {
    let state: ARState
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            // Map Vision normalized coordinates to screen coordinates
            // Vision coordinates have origin at bottom-left
            let obs = state.boardObservation
            let tl = CGPoint(x: obs.topLeft.x * size.width, y: (1 - obs.topLeft.y) * size.height)
            let tr = CGPoint(x: obs.topRight.x * size.width, y: (1 - obs.topRight.y) * size.height)
            let bl = CGPoint(x: obs.bottomLeft.x * size.width, y: (1 - obs.bottomLeft.y) * size.height)
            let br = CGPoint(x: obs.bottomRight.x * size.width, y: (1 - obs.bottomRight.y) * size.height)
            
            // 1. Draw Board Boundary (Subtle highlight)
            Path { path in
                path.move(to: tl)
                path.addLine(to: tr)
                path.addLine(to: br)
                path.addLine(to: bl)
                path.closeSubpath()
            }
            .stroke(Color.green.opacity(0.4), lineWidth: 2)
            
            // 2. Map shot lines
            // The recommendation's shot is in mm coordinates (e.g. 0 to 740).
            // We need a helper to map 2D board mm -> normalized 2D (0.0 to 1.0)
            // -> Screen Quad (tl, tr, bl, br) using Bilinear Interpolation.
            
            let shot = state.recommendation.shot
            
            // Draw lines using a custom Canvas or Paths
            Canvas { context, _ in
                // Helper to map a point in mm to screen space using bilinear interpolation
                func mapToScreen(_ mmPoint: CGPoint) -> CGPoint {
                    // Convert mm to normalized [0, 1] relative to the board
                    let nx = mmPoint.x / CGFloat(BoardConfig.playingAreaDimension)
                    let ny = mmPoint.y / CGFloat(BoardConfig.playingAreaDimension)
                    
                    // Bilinear interpolation between the 4 corners
                    // Top edge interpolation
                    let topX = tl.x + (tr.x - tl.x) * nx
                    let topY = tl.y + (tr.y - tl.y) * nx
                    
                    // Bottom edge interpolation
                    let bottomX = bl.x + (br.x - bl.x) * nx
                    let bottomY = bl.y + (br.y - bl.y) * nx
                    
                    // Vertical interpolation
                    let finalX = topX + (bottomX - topX) * ny
                    let finalY = topY + (bottomY - topY) * ny
                    
                    return CGPoint(x: finalX, y: finalY)
                }
                
                // Striker Path (Green)
                if shot.strikerPath.count >= 2 {
                    var p = Path()
                    let start = mapToScreen(shot.strikerPath[0])
                    p.move(to: start)
                    for i in 1..<shot.strikerPath.count {
                        p.addLine(to: mapToScreen(shot.strikerPath[i]))
                    }
                    context.stroke(p, with: .color(.green), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    
                    // Striker starting position circle
                    let strikerRadius: CGFloat = 16
                    context.fill(
                        Circle().path(in: CGRect(x: start.x - strikerRadius, y: start.y - strikerRadius, width: strikerRadius * 2, height: strikerRadius * 2)),
                        with: .color(.white)
                    )
                    context.stroke(
                        Circle().path(in: CGRect(x: start.x - strikerRadius, y: start.y - strikerRadius, width: strikerRadius * 2, height: strikerRadius * 2)),
                        with: .color(.green),
                        lineWidth: 3
                    )
                }
                
                // Coin Path (Yellow)
                if shot.coinPath.count >= 2 {
                    var p = Path()
                    let start = mapToScreen(shot.coinPath[0])
                    p.move(to: start)
                    for i in 1..<shot.coinPath.count {
                        p.addLine(to: mapToScreen(shot.coinPath[i]))
                    }
                    context.stroke(p, with: .color(.yellow), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Target coin circle
                    let coinRadius: CGFloat = 12
                    context.fill(
                        Circle().path(in: CGRect(x: start.x - coinRadius, y: start.y - coinRadius, width: coinRadius * 2, height: coinRadius * 2)),
                        with: .color(state.recommendation.pocketableCoins.first?.coin.coinType == .blackCoin ? Color(white: 0.15) : .white)
                    )
                    context.stroke(
                        Circle().path(in: CGRect(x: start.x - coinRadius, y: start.y - coinRadius, width: coinRadius * 2, height: coinRadius * 2)),
                        with: .color(.yellow),
                        lineWidth: 2
                    )
                }
                
                // Target Pocket Highlight
                let pocketPos = Pocket(id: shot.targetPocket).positionMM
                let pocketScreen = mapToScreen(pocketPos)
                context.fill(
                    Circle().path(in: CGRect(x: pocketScreen.x - 20, y: pocketScreen.y - 20, width: 40, height: 40)),
                    with: .color(Color.orange.opacity(0.7))
                )
            }
        }
    }
}

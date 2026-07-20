import SwiftUI

// MARK: - Board Overlay
/// Renders the shot visualization overlay on top of the captured board image.
/// Shows striker path (green), coin path (yellow), target highlights.

struct BoardOverlay: View {
    
    let recommendation: Recommendation
    let size: CGSize
    
    private let coordinateMapper = CoordinateMapper()
    
    var body: some View {
        Canvas { context, canvasSize in
            let shot = recommendation.shot
            let scale = canvasSize.width / CGFloat(BoardConfig.playingAreaDimension)
            let offset = canvasSize.width / 2.0
            
            // Helper: board mm → canvas coordinates
            func toCanvas(_ point: CGPoint) -> CGPoint {
                CGPoint(
                    x: point.x * scale + offset,
                    y: point.y * scale + offset
                )
            }
            
            // 1. Draw target pocket highlight
            let pocketPos = Pocket(id: shot.targetPocket).positionMM
            let pocketCanvas = toCanvas(pocketPos)
            let pocketHighlightRadius: CGFloat = 20 * scale
            
            context.fill(
                Circle().path(in: CGRect(
                    x: pocketCanvas.x - pocketHighlightRadius,
                    y: pocketCanvas.y - pocketHighlightRadius,
                    width: pocketHighlightRadius * 2,
                    height: pocketHighlightRadius * 2
                )),
                with: .color(Color(
                    red: AppConstants.targetPocketHighlightColor.r,
                    green: AppConstants.targetPocketHighlightColor.g,
                    blue: AppConstants.targetPocketHighlightColor.b,
                    opacity: AppConstants.targetPocketHighlightColor.a
                ))
            )
            
            // 2. Draw coin path (yellow) — target coin to pocket
            if shot.coinPath.count >= 2 {
                var coinPathShape = Path()
                let firstCoinPoint = toCanvas(shot.coinPath[0])
                coinPathShape.move(to: firstCoinPoint)
                
                for i in 1..<shot.coinPath.count {
                    coinPathShape.addLine(to: toCanvas(shot.coinPath[i]))
                }
                
                context.stroke(
                    coinPathShape,
                    with: .color(Color(
                        red: AppConstants.targetPathColor.r,
                        green: AppConstants.targetPathColor.g,
                        blue: AppConstants.targetPathColor.b,
                        opacity: AppConstants.targetPathColor.a
                    )),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        dash: [8, 4]
                    )
                )
            }
            
            // 3. Draw striker path (green) — striker to contact point
            if shot.strikerPath.count >= 2 {
                var strikerPathShape = Path()
                let firstStrikerPoint = toCanvas(shot.strikerPath[0])
                strikerPathShape.move(to: firstStrikerPoint)
                
                for i in 1..<shot.strikerPath.count {
                    strikerPathShape.addLine(to: toCanvas(shot.strikerPath[i]))
                }
                
                context.stroke(
                    strikerPathShape,
                    with: .color(Color(
                        red: AppConstants.strikerPathColor.r,
                        green: AppConstants.strikerPathColor.g,
                        blue: AppConstants.strikerPathColor.b,
                        opacity: AppConstants.strikerPathColor.a
                    )),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round
                    )
                )
            }
            
            // 4. Draw target coin highlight
            let coinPos = toCanvas(shot.targetCoin.position)
            let coinHighlightRadius = CGFloat(BoardConfig.coinRadius) * scale * 1.5
            
            context.stroke(
                Circle().path(in: CGRect(
                    x: coinPos.x - coinHighlightRadius,
                    y: coinPos.y - coinHighlightRadius,
                    width: coinHighlightRadius * 2,
                    height: coinHighlightRadius * 2
                )),
                with: .color(Color(
                    red: AppConstants.targetCoinHighlightColor.r,
                    green: AppConstants.targetCoinHighlightColor.g,
                    blue: AppConstants.targetCoinHighlightColor.b,
                    opacity: AppConstants.targetCoinHighlightColor.a
                )),
                lineWidth: 3
            )
            
            // 5. Draw striker placement marker
            let strikerPos = toCanvas(shot.strikerPosition)
            let strikerMarkerRadius = CGFloat(BoardConfig.strikerRadius) * scale
            
            context.stroke(
                Circle().path(in: CGRect(
                    x: strikerPos.x - strikerMarkerRadius,
                    y: strikerPos.y - strikerMarkerRadius,
                    width: strikerMarkerRadius * 2,
                    height: strikerMarkerRadius * 2
                )),
                with: .color(Color(
                    red: AppConstants.strikerMarkerColor.r,
                    green: AppConstants.strikerMarkerColor.g,
                    blue: AppConstants.strikerMarkerColor.b,
                    opacity: AppConstants.strikerMarkerColor.a
                )),
                style: StrokeStyle(lineWidth: 2, dash: [6, 3])
            )
            
            // Striker center dot
            let dotSize: CGFloat = 6
            context.fill(
                Circle().path(in: CGRect(
                    x: strikerPos.x - dotSize / 2,
                    y: strikerPos.y - dotSize / 2,
                    width: dotSize,
                    height: dotSize
                )),
                with: .color(Color(
                    red: AppConstants.strikerMarkerColor.r,
                    green: AppConstants.strikerMarkerColor.g,
                    blue: AppConstants.strikerMarkerColor.b,
                    opacity: 1.0
                ))
            )
        }
        .allowsHitTesting(false)
    }
}

package com.example.carromaicoach.ui.main

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import com.example.carromaicoach.config.BoardConfig
import com.example.carromaicoach.data.models.Board
import com.example.carromaicoach.data.models.DetectionType
import com.example.carromaicoach.data.models.Recommendation
import com.example.carromaicoach.vision.PerspectiveCorrector

import androidx.compose.ui.graphics.drawscope.withTransform

@Composable
fun AROverlayCanvas(
    board: Board?,
    recommendation: Recommendation?,
    perspectiveCorrector: PerspectiveCorrector,
    scaleX: Float = 1f,
    scaleY: Float = 1f
) {
    Canvas(modifier = Modifier.fillMaxSize()) {
        withTransform({
            scale(scaleX = scaleX, scaleY = scaleY, pivot = Offset.Zero)
        }) {
        if (board != null && board.corners.size == 4) {
            // Draw board bounding box
            val path = Path().apply {
                moveTo(board.corners[0].x, board.corners[0].y)
                lineTo(board.corners[1].x, board.corners[1].y)
                lineTo(board.corners[2].x, board.corners[2].y)
                lineTo(board.corners[3].x, board.corners[3].y)
                close()
            }
            drawPath(
                path = path,
                color = Color.Green,
                style = Stroke(width = 5f)
            )

            // Draw coins
            board.coins.forEach { coin ->
                val cameraPos = perspectiveCorrector.mmToCamera(coin.position, BoardConfig.halfPlayingArea)
                val color = when (coin.coinType) {
                    DetectionType.BLACK_COIN -> Color.Black
                    DetectionType.WHITE_COIN -> Color.White
                    DetectionType.QUEEN -> Color.Red
                    DetectionType.STRIKER -> Color.Blue
                }
                drawCircle(
                    color = color,
                    radius = 20f,
                    center = cameraPos
                )
            }
            
            // Draw recommendation path
            if (recommendation != null) {
                // Striker path
                val strikerPath = Path()
                recommendation.shot.strikerPath.forEachIndexed { index, point ->
                    val camPos = perspectiveCorrector.mmToCamera(point, BoardConfig.halfPlayingArea)
                    if (index == 0) strikerPath.moveTo(camPos.x, camPos.y)
                    else strikerPath.lineTo(camPos.x, camPos.y)
                }
                drawPath(
                    path = strikerPath,
                    color = Color.Cyan,
                    style = Stroke(width = 8f)
                )

                // Coin path
                val coinPath = Path()
                recommendation.shot.coinPath.forEachIndexed { index, point ->
                    val camPos = perspectiveCorrector.mmToCamera(point, BoardConfig.halfPlayingArea)
                    if (index == 0) coinPath.moveTo(camPos.x, camPos.y)
                    else coinPath.lineTo(camPos.x, camPos.y)
                }
                drawPath(
                    path = coinPath,
                    color = Color.Yellow,
                    style = Stroke(width = 8f)
                )
                
                // Draw target crosshair
                val lastPoint = recommendation.shot.coinPath.lastOrNull()
                if (lastPoint != null) {
                    val camPos = perspectiveCorrector.mmToCamera(lastPoint, BoardConfig.halfPlayingArea)
                    drawCircle(
                        color = Color.Red,
                        radius = 25f,
                        center = camPos,
                        style = Stroke(width = 4f)
                    )
                }
                
                // Draw Power Indicator
                val powerLevel = recommendation.shot.displayPower // 1 to 10
                val strikerStartPos = recommendation.shot.strikerPath.firstOrNull()
                if (strikerStartPos != null) {
                    val camPos = perspectiveCorrector.mmToCamera(strikerStartPos, BoardConfig.halfPlayingArea)
                    val powerColor = when {
                        powerLevel < 4 -> Color.Green
                        powerLevel < 7 -> Color.Yellow
                        else -> Color.Red
                    }
                    
                    // Draw a bar representing power next to the striker
                    val barHeight = powerLevel * 10f
                    val barWidth = 15f
                    val offsetX = 40f
                    
                    drawRect(
                        color = powerColor,
                        topLeft = Offset(camPos.x + offsetX, camPos.y - barHeight),
                        size = androidx.compose.ui.geometry.Size(barWidth, barHeight)
                    )
                }
            }
            }
        }
    }
}

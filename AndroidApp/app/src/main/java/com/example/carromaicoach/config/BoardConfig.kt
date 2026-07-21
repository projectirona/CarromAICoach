package com.example.carromaicoach.config

import androidx.compose.ui.geometry.Offset

object BoardConfig {
    const val outerDimension = 1321.0
    const val playingAreaDimension = 737.0
    const val halfPlayingArea = playingAreaDimension / 2.0
    
    const val pocketDiameter = 44.5
    const val pocketRadius = pocketDiameter / 2.0
    const val pocketCaptureRadius = 22.25
    
    val pocketPositions = listOf(
        Offset(0f, 0f),
        Offset(1f, 0f),
        Offset(0f, 1f),
        Offset(1f, 1f)
    )
    
    val pocketPositionsMM = listOf(
        Offset(-halfPlayingArea.toFloat(), -halfPlayingArea.toFloat()),
        Offset(halfPlayingArea.toFloat(), -halfPlayingArea.toFloat()),
        Offset(-halfPlayingArea.toFloat(), halfPlayingArea.toFloat()),
        Offset(halfPlayingArea.toFloat(), halfPlayingArea.toFloat())
    )
    
    const val coinDiameter = 31.0
    const val coinRadius = coinDiameter / 2.0
    const val queenDiameter = 31.0
    const val queenRadius = queenDiameter / 2.0
    
    const val strikerDiameter = 75.0
    const val strikerRadius = strikerDiameter / 2.0
    
    const val coinMass = 5.0
    const val strikerMass = 15.0
    
    const val baselineOffset = 47.0
    const val baselineCircleRadius = 25.0
    const val baselineY = halfPlayingArea - baselineOffset
    const val baselineMinX = -halfPlayingArea + baselineOffset + strikerRadius
    const val baselineMaxX = halfPlayingArea - baselineOffset - strikerRadius
    
    const val centerCircleRadius = 85.0
    const val outerCenterCircleRadius = 160.0
}

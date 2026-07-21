package com.example.carromaicoach.engine

import androidx.compose.ui.geometry.Offset
import com.example.carromaicoach.config.BoardConfig

object PhysicsConstants {
    val halfBoard = BoardConfig.halfPlayingArea
    
    val minX = -halfBoard
    val maxX = halfBoard
    val minY = -halfBoard
    val maxY = halfBoard
    
    val pocketCaptureRadius = BoardConfig.pocketCaptureRadius
    val pocketCenters: List<Offset> = BoardConfig.pocketPositionsMM
    
    const val surfaceFriction = 0.15
    const val rollingFriction = 0.10
    
    const val coinCoinRestitution = 0.85
    const val coinCushionRestitution = 0.70
    const val strikerCoinRestitution = 0.88
    
    const val timeStep = 0.001 // AppConfig.physicsTimeStep
    const val maxSimulationTime = 5.0 // AppConfig.maxSimulationDuration
    
    const val restThreshold = 0.5 // AppConfig.restVelocityThreshold
    const val restThresholdSquared = restThreshold * restThreshold
    
    const val gravity = 9810.0
    
    val coinRadius = BoardConfig.coinRadius
    val strikerRadius = BoardConfig.strikerRadius
    val coinMass = BoardConfig.coinMass
    val strikerMass = BoardConfig.strikerMass
    
    const val minLaunchVelocity = 500.0
    const val maxLaunchVelocity = 5000.0
}

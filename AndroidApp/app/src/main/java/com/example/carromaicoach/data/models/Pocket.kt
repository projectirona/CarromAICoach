package com.example.carromaicoach.data.models

import androidx.compose.ui.geometry.Offset
import com.example.carromaicoach.config.BoardConfig

enum class PocketID(val value: String) {
    TOP_LEFT("TL"),
    TOP_RIGHT("TR"),
    BOTTOM_LEFT("BL"),
    BOTTOM_RIGHT("BR");

    val index: Int
        get() = when (this) {
            TOP_LEFT -> 0
            TOP_RIGHT -> 1
            BOTTOM_LEFT -> 2
            BOTTOM_RIGHT -> 3
        }
        
    val displayName: String
        get() = when (this) {
            TOP_LEFT -> "Top Left"
            TOP_RIGHT -> "Top Right"
            BOTTOM_LEFT -> "Bottom Left"
            BOTTOM_RIGHT -> "Bottom Right"
        }
}

data class Pocket(val id: PocketID) {
    val radius = BoardConfig.pocketRadius
    val captureRadius = BoardConfig.pocketCaptureRadius
    val positionMM: Offset = BoardConfig.pocketPositionsMM[id.index]
    val positionNormalized: Offset = BoardConfig.pocketPositions[id.index]

    companion object {
        fun allPockets(): List<Pocket> {
            return PocketID.values().map { Pocket(it) }
        }
    }
}

package com.example.carromaicoach.data.models

import androidx.compose.ui.geometry.Offset

data class Coin(
    val id: String,
    val coinType: DetectionType,
    var position: Offset,
    var velocity: Offset = Offset.Zero,
    val physicalRadius: Double = coinType.physicalRadiusMM,
    val mass: Double = coinType.physicalMassGrams,
    var confidence: Float = 1.0f,
    var isVisible: Boolean = true,
    var isPocketed: Boolean = false
) {
    val detectionType: DetectionType
        get() = coinType
        
    val radius: Double
        get() = physicalRadius
        
    val bodyRadius: Double
        get() = physicalRadius
        
    val bodyMass: Double
        get() = mass
        
    fun belongsTo(playerColor: PlayerColor): Boolean {
        return when (playerColor) {
            PlayerColor.BLACK -> coinType == DetectionType.BLACK_COIN
            PlayerColor.WHITE -> coinType == DetectionType.WHITE_COIN
        }
    }
    
    val isQueen: Boolean
        get() = coinType == DetectionType.QUEEN
        
    val isStriker: Boolean
        get() = coinType == DetectionType.STRIKER
        
    val isGameCoin: Boolean
        get() = coinType.isGameCoin
        
    val isInPlay: Boolean
        get() = isVisible && !isPocketed

    companion object {
        fun black(index: Int, position: Offset, confidence: Float = 1.0f): Coin {
            return Coin(id = "black_$index", coinType = DetectionType.BLACK_COIN, position = position, confidence = confidence)
        }
        
        fun white(index: Int, position: Offset, confidence: Float = 1.0f): Coin {
            return Coin(id = "white_$index", coinType = DetectionType.WHITE_COIN, position = position, confidence = confidence)
        }
        
        fun queen(position: Offset, confidence: Float = 1.0f): Coin {
            return Coin(id = "queen", coinType = DetectionType.QUEEN, position = position, confidence = confidence)
        }
        
        fun striker(position: Offset): Coin {
            return Coin(id = "striker", coinType = DetectionType.STRIKER, position = position, confidence = 1.0f)
        }
    }
}

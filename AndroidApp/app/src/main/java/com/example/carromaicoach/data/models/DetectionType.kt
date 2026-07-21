package com.example.carromaicoach.data.models

enum class DetectionType(val value: String) {
    BLACK_COIN("black"),
    WHITE_COIN("white"),
    QUEEN("queen"),
    STRIKER("striker");

    val displayName: String
        get() = when (this) {
            BLACK_COIN -> "Black"
            WHITE_COIN -> "White"
            QUEEN -> "Queen"
            STRIKER -> "Striker"
        }

    val isGameCoin: Boolean
        get() = this == BLACK_COIN || this == WHITE_COIN || this == QUEEN

    val physicalRadiusMM: Double
        get() = when (this) {
            BLACK_COIN, WHITE_COIN, QUEEN -> 15.9 // Based on BoardConfig.coinRadius
            STRIKER -> 20.6 // Based on BoardConfig.strikerRadius
        }
        
    val physicalMassGrams: Double
        get() = when (this) {
            BLACK_COIN, WHITE_COIN, QUEEN -> 5.5 // Based on BoardConfig.coinMass
            STRIKER -> 15.0 // Based on BoardConfig.strikerMass
        }
}

package com.example.carromaicoach.data.models

import androidx.compose.ui.geometry.Offset
import kotlin.math.max
import kotlin.math.min

enum class ShotType {
    DIRECT,
    CUT,
    REBOUND,
    DOUBLE_REBOUND
}

data class Shot(
    val id: String = java.util.UUID.randomUUID().toString(),
    val shotType: ShotType,
    val strikerPosition: Offset,
    val aimAngle: Double,
    var power: Double,
    val targetCoin: Coin,
    val targetPocket: PocketID,
    val rebounds: Int,
    val strikerPath: List<Offset>,
    val coinPath: List<Offset>,
    val intermediateCoinIds: List<String> = emptyList(),
    val cutAngle: Double = 0.0
) {
    val displayPower: Int
        get() {
            val normalized = min(1.0, max(0.0, power / 5000.0))
            return (normalized * 9.0).toInt() + 1 // Scale 1 to 10
        }
}

data class PocketableCoin(
    val coin: Coin,
    val pocket: PocketID,
    val shotType: ShotType,
    val probability: Double
)

data class Recommendation(
    val id: String = java.util.UUID.randomUUID().toString(),
    val shot: Shot,
    val probability: Double,
    val pocketableCoins: List<PocketableCoin>,
    val reasoning: String,
    val boardSnapshot: Board,
    val analysisTime: Double
) {
    val pocketableCoinsCount: Int = pocketableCoins.size
}

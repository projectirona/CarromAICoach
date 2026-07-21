package com.example.carromaicoach.data.models

import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect

data class Board(
    var corners: List<Offset>,
    var coins: List<Coin> = emptyList(),
    var striker: Coin? = null
) {
    val pockets: List<Pocket> = Pocket.allPockets()
    val playingArea: Rect = Rect(0f, 0f, 1f, 1f)
    val center: Offset = Offset(0f, 0f)

    val queen: Coin?
        get() = coins.firstOrNull { it.isQueen && it.isInPlay }

    fun coins(ofType: DetectionType): List<Coin> {
        return coins.filter { it.coinType == ofType && it.isInPlay }
    }

    fun playerCoins(forColor: PlayerColor): List<Coin> {
        return coins.filter { it.belongsTo(forColor) && it.isInPlay }
    }

    fun opponentCoins(forColor: PlayerColor): List<Coin> {
        val opponentColor = if (forColor == PlayerColor.BLACK) PlayerColor.WHITE else PlayerColor.BLACK
        return playerCoins(opponentColor)
    }

    fun remainingCount(forColor: PlayerColor): Int {
        return playerCoins(forColor).size
    }

    val activeCoins: List<Coin>
        get() = coins.filter { it.isInPlay }
}

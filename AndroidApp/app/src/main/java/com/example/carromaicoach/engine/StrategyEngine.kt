package com.example.carromaicoach.engine

import com.example.carromaicoach.data.models.*

class StrategyEngine(
    private val shotGenerator: ShotGenerator = ShotGenerator(),
    private val shotEvaluator: ShotEvaluator = ShotEvaluator()
) {
    fun analyze(board: Board, playerColor: PlayerColor): Recommendation? {
        val playerCoins = board.playerCoins(playerColor)
        if (playerCoins.isEmpty()) return null

        val allCandidates = mutableListOf<PocketableCoin>()
        var bestShot: Shot? = null
        var bestProb = -1.0
        var bestCoin: Coin? = null
        var bestPocket: PocketID? = null

        // 1. Generate all possible direct shots for all of the player's coins
        for (coin in playerCoins) {
            val shots = shotGenerator.generateDirectShots(board, coin)
            
            for (shot in shots) {
                // 2. Evaluate the shot using raycasting
                val prob = shotEvaluator.evaluate(shot, board)
                if (prob > 0.0) {
                    allCandidates.add(
                        PocketableCoin(
                            coin = coin,
                            pocket = shot.targetPocket,
                            shotType = shot.shotType,
                            probability = prob
                        )
                    )
                    
                    if (prob > bestProb) {
                        bestProb = prob
                        bestShot = shot
                        bestCoin = coin
                        bestPocket = shot.targetPocket
                    }
                }
            }
        }

        if (bestShot == null || bestCoin == null || bestPocket == null) return null
        
        return Recommendation(
            shot = bestShot,
            probability = bestProb,
            pocketableCoins = allCandidates,
            reasoning = "Best probability shot evaluated using raycasting.",
            boardSnapshot = board,
            analysisTime = 0.05
        )
    }
}

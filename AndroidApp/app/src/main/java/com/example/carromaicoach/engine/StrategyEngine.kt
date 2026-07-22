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
        
        // 3. If the best direct shot is terrible (prob < 0.7), evaluate rebounds
        if (bestProb < 0.7) {
            for (coin in playerCoins) {
                val reboundShots = shotGenerator.generateReboundShots(board, coin)
                for (shot in reboundShots) {
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
        }
        // 4. If the best rebound shot is also terrible, evaluate combinations
        if (bestProb < 0.6) {
            for (coin in playerCoins) {
                val combinationShots = shotGenerator.generateCombinationShots(board, coin, board.coins)
                for (shot in combinationShots) {
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
        }
        
        var reasoningText = "Best probability shot evaluated using raycasting."
        
        // 5. Queen Coverage Logic (1-ply Lookahead)
        // If the best shot is the Queen, we MUST have a cover shot lined up for the next turn.
        if (bestCoin != null && bestCoin.coinType == com.example.carromaicoach.data.models.DetectionType.QUEEN) {
            // Find the best direct shot for any of the player's coins, pretending the Queen is gone
            var bestCoverProb = 0.0
            val boardWithoutQueen = board.copy(coins = board.coins.filter { it.id != bestCoin.id })
            
            for (coin in playerCoins) {
                if (coin.id == bestCoin.id) continue // Can't cover with the Queen
                
                val coverShots = shotGenerator.generateDirectShots(boardWithoutQueen, coin)
                for (shot in coverShots) {
                    val prob = shotEvaluator.evaluate(shot, boardWithoutQueen)
                    if (prob > bestCoverProb) {
                        bestCoverProb = prob
                    }
                }
            }
            
            // If the best cover shot is less than 70%, we shouldn't shoot the Queen right now!
            if (bestCoverProb < 0.7) {
                // Demote the Queen shot so the AI picks a defensive shot or another coin instead
                bestProb = 0.1
                reasoningText = "Queen shot available, but demoted because there is no reliable cover shot (>70%)."
            } else {
                reasoningText = "Queen shot recommended. A strong cover shot is available for the next turn."
            }
        }

        if (bestShot == null || bestCoin == null || bestPocket == null) return null
        
        return Recommendation(
            shot = bestShot,
            probability = bestProb,
            pocketableCoins = allCandidates,
            reasoning = reasoningText,
            boardSnapshot = board,
            analysisTime = 0.05
        )
    }
}

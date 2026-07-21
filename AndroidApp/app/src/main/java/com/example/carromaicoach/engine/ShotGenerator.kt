package com.example.carromaicoach.engine

import androidx.compose.ui.geometry.Offset
import com.example.carromaicoach.config.BoardConfig
import com.example.carromaicoach.data.models.Board
import com.example.carromaicoach.data.models.Coin
import com.example.carromaicoach.data.models.PocketID
import com.example.carromaicoach.data.models.Shot
import com.example.carromaicoach.data.models.ShotType
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

class ShotGenerator {
    
    // Generates a list of possible direct shots for a given target coin
    fun generateDirectShots(board: Board, targetCoin: Coin): List<Shot> {
        val shots = mutableListOf<Shot>()
        
        // Try all 4 pockets
        for (pocket in board.pockets) {
            val shot = generateShotForPocket(targetCoin, pocket.id, pocket.positionMM)
            if (shot != null) shots.add(shot)
        }
        
        return shots
    }
    
    private fun generateShotForPocket(targetCoin: Coin, pocketId: PocketID, pocketPosition: Offset): Shot? {
        val aimDx = pocketPosition.x - targetCoin.position.x
        val aimDy = pocketPosition.y - targetCoin.position.y
        val aimAngle = atan2(aimDy.toDouble(), aimDx.toDouble())
        
        // Calculate contact point (striker hits the coin opposite to the pocket)
        val contactDist = PhysicsConstants.coinRadius + PhysicsConstants.strikerRadius
        val contactX = targetCoin.position.x - contactDist * cos(aimAngle)
        val contactY = targetCoin.position.y - contactDist * sin(aimAngle)
        
        // Find striker baseline position
        val baselineY = BoardConfig.baselineY
        
        // Basic projection (assuming straight line from baseline to contact point)
        val t = (baselineY - contactY) / sin(aimAngle)
        val baselineX = contactX + t * cos(aimAngle)
        
        // If the shot requires the striker to be placed outside the baseline, it's impossible
        if (baselineX < BoardConfig.baselineMinX || baselineX > BoardConfig.baselineMaxX) {
            return null
        }
        
        val strikerPosition = Offset(baselineX.toFloat(), baselineY.toFloat())
        
        // Re-calculate true aim angle from baseline
        val trueAimDx = contactX - baselineX
        val trueAimDy = contactY - baselineY
        val trueAimAngle = atan2(trueAimDy.toDouble(), trueAimDx.toDouble())
        
        val power = 3500.0 // Default power for direct shots
        
        return Shot(
            shotType = ShotType.DIRECT,
            strikerPosition = strikerPosition,
            aimAngle = trueAimAngle,
            power = power,
            targetCoin = targetCoin,
            targetPocket = pocketId,
            rebounds = 0,
            strikerPath = listOf(strikerPosition, Offset(contactX.toFloat(), contactY.toFloat())),
            coinPath = listOf(targetCoin.position, pocketPosition)
        )
    }
    // Generates a list of possible single-cushion rebound shots
    fun generateReboundShots(board: Board, targetCoin: Coin): List<Shot> {
        val shots = mutableListOf<Shot>()
        
        for (pocket in board.pockets) {
            val aimDx = pocket.positionMM.x - targetCoin.position.x
            val aimDy = pocket.positionMM.y - targetCoin.position.y
            val pocketAngle = atan2(aimDy.toDouble(), aimDx.toDouble())
            
            val contactDist = PhysicsConstants.coinRadius + PhysicsConstants.strikerRadius
            val contactX = targetCoin.position.x - contactDist * cos(pocketAngle)
            val contactY = targetCoin.position.y - contactDist * sin(pocketAngle)
            
            val halfBoard = BoardConfig.halfPlayingArea
            val baselineY = BoardConfig.baselineY
            
            // 4 Cushions: Top, Bottom, Left, Right
            val cushions = listOf(
                Pair("TOP", -halfBoard),
                Pair("BOTTOM", halfBoard),
                Pair("LEFT", -halfBoard),
                Pair("RIGHT", halfBoard)
            )
            
            for ((side, coord) in cushions) {
                var ghostX = contactX
                var ghostY = contactY
                
                if (side == "LEFT" || side == "RIGHT") {
                    ghostX = 2 * coord - contactX
                } else {
                    ghostY = 2 * coord - contactY
                }
                
                // Striker aims at (ghostX, ghostY) from baseline (baselineX, baselineY)
                // We know baselineY, we just need to pick a baselineX that can hit the cushion.
                // To keep it simple, we can scan baselineX from min to max and find a valid path.
                // Or mathematically, if we choose a baselineX, the line equation gives us the cushion hit point.
                // We will try 5 different baseline positions (left, center-left, center, center-right, right)
                val numSamples = 5
                val step = (BoardConfig.baselineMaxX - BoardConfig.baselineMinX) / (numSamples - 1)
                
                for (i in 0 until numSamples) {
                    val baselineX = BoardConfig.baselineMinX + i * step
                    val strikerPos = Offset(baselineX.toFloat(), baselineY.toFloat())
                    
                    val aimDxStr = ghostX - baselineX
                    val aimDyStr = ghostY - baselineY
                    val aimAngle = atan2(aimDyStr, aimDxStr)
                    
                    // Find intersection with the cushion
                    var hitX = 0.0
                    var hitY = 0.0
                    var valid = false
                    
                    if (side == "LEFT" || side == "RIGHT") {
                        val t = (coord - baselineX) / aimDxStr
                        hitX = coord
                        hitY = baselineY + t * aimDyStr
                        if (t > 0 && hitY >= -halfBoard && hitY <= halfBoard) valid = true
                    } else {
                        val t = (coord - baselineY) / aimDyStr
                        hitX = baselineX + t * aimDxStr
                        hitY = coord
                        if (t > 0 && hitX >= -halfBoard && hitX <= halfBoard) valid = true
                    }
                    
                    if (valid) {
                        val cushionPos = Offset(hitX.toFloat(), hitY.toFloat())
                        val power = 4500.0 // Rebounds require more power
                        
                        shots.add(Shot(
                            shotType = ShotType.REBOUND,
                            strikerPosition = strikerPos,
                            aimAngle = aimAngle,
                            power = power,
                            targetCoin = targetCoin,
                            targetPocket = pocket.id,
                            rebounds = 1,
                            strikerPath = listOf(strikerPos, cushionPos, Offset(contactX.toFloat(), contactY.toFloat())),
                            coinPath = listOf(targetCoin.position, pocket.positionMM)
                        ))
                    }
                }
            }
        }
        return shots
    }
}

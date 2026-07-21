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
}

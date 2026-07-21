package com.example.carromaicoach.engine

import androidx.compose.ui.geometry.Offset
import com.example.carromaicoach.data.models.Board
import com.example.carromaicoach.data.models.Coin
import com.example.carromaicoach.data.models.Shot

class ShotEvaluator(private val physicsEngine: PhysicsEngine = PhysicsEngine()) {
    
    // Evaluates a shot to determine if it is blocked by other coins and its probability of success
    fun evaluate(shot: Shot, board: Board): Double {
        var totalDistance = 0.0
        
        // 1. Raycast the striker path segments
        for (i in 0 until shot.strikerPath.size - 1) {
            val start = shot.strikerPath[i]
            val end = shot.strikerPath[i + 1]
            if (isPathBlocked(start, end, board.coins, ignoreCoinId = shot.targetCoin.id)) {
                return 0.0 // Blocked
            }
            val dx = end.x - start.x
            val dy = end.y - start.y
            totalDistance += Math.sqrt((dx * dx + dy * dy).toDouble())
        }
        
        // 2. Raycast the target coin path segments
        for (i in 0 until shot.coinPath.size - 1) {
            val start = shot.coinPath[i]
            val end = shot.coinPath[i + 1]
            if (isPathBlocked(start, end, board.coins, ignoreCoinId = shot.targetCoin.id)) {
                return 0.0
            }
            val dx = end.x - start.x
            val dy = end.y - start.y
            totalDistance += Math.sqrt((dx * dx + dy * dy).toDouble())
        }
        
        // 3. Update the shot's power based on total distance
        // Base power of 1000 + 3.0 per mm
        shot.power = 1000.0 + (totalDistance * 3.0)
        
        // 4. Probability calculation
        // A simple heuristic: success probability degrades over distance and rebounds
        // e.g. 1.0 at 0mm, 0.5 at 1000mm
        var prob = 1.0 - (totalDistance / 2000.0)
        
        if (shot.shotType == com.example.carromaicoach.data.models.ShotType.REBOUND) {
            prob *= 0.8 // Rebounds are inherently 20% harder
        }
        
        prob = prob.coerceIn(0.1, 0.95)
        
        return prob
    }
    
    private fun isPathBlocked(start: Offset, end: Offset, coins: List<Coin>, ignoreCoinId: String): Boolean {
        // Line equation: A*x + B*y + C = 0
        val a = end.y - start.y
        val b = start.x - end.x
        val c = end.x * start.y - start.x * end.y
        
        val lineLengthSq = a * a + b * b
        if (lineLengthSq < 0.1f) return false
        
        val collisionRadiusSq = Math.pow(PhysicsConstants.coinRadius * 2.0, 2.0)
        
        // Check bounding box of the line segment to avoid checking coins far behind/ahead
        val minX = Math.min(start.x, end.x) - PhysicsConstants.coinRadius * 2
        val maxX = Math.max(start.x, end.x) + PhysicsConstants.coinRadius * 2
        val minY = Math.min(start.y, end.y) - PhysicsConstants.coinRadius * 2
        val maxY = Math.max(start.y, end.y) + PhysicsConstants.coinRadius * 2
        
        for (coin in coins) {
            if (coin.id == ignoreCoinId) continue
            
            // Check bounding box first
            if (coin.position.x < minX || coin.position.x > maxX || 
                coin.position.y < minY || coin.position.y > maxY) {
                continue
            }
            
            // Perpendicular distance from coin center to line
            val distSq = Math.pow((a * coin.position.x + b * coin.position.y + c).toDouble(), 2.0) / lineLengthSq
            if (distSq < collisionRadiusSq) {
                // The infinite line intersects, verify it's within the line segment
                // Project coin onto line
                val dot = (coin.position.x - start.x) * (end.x - start.x) + 
                          (coin.position.y - start.y) * (end.y - start.y)
                if (dot > 0 && dot < lineLengthSq) {
                    return true // Blocked!
                }
            }
        }
        
        return false
    }
}

package com.example.carromaicoach.engine

import androidx.compose.ui.geometry.Offset
import com.example.carromaicoach.data.models.PocketID
import kotlin.math.sqrt

object CushionRebound {

    fun applyAll(bodies: MutableList<PhysicsBody>): List<Pair<String, PocketID>> {
        val newlyPocketed = mutableListOf<Pair<String, PocketID>>()
        for (body in bodies) {
            if (!body.isActive) continue
            
            // Check pocketing
            val pocketedIn = checkPocketing(body)
            if (pocketedIn != null) {
                body.isPocketed = true
                body.pocketedIn = pocketedIn
                body.velocity = Offset.Zero
                newlyPocketed.add(Pair(body.id, pocketedIn))
                continue
            }
            
            // Rebound from cushions
            checkAndResolveRebounds(body)
        }
        return newlyPocketed
    }
    
    private fun checkPocketing(body: PhysicsBody): PocketID? {
        val captureRadiusSq = PhysicsConstants.pocketCaptureRadius * PhysicsConstants.pocketCaptureRadius
        
        for (i in PhysicsConstants.pocketCenters.indices) {
            val center = PhysicsConstants.pocketCenters[i]
            val dx = body.position.x - center.x
            val dy = body.position.y - center.y
            val distSq = (dx * dx) + (dy * dy)
            
            if (distSq <= captureRadiusSq) {
                return PocketID.values()[i]
            }
        }
        return null
    }

    private fun checkAndResolveRebounds(body: PhysicsBody) {
        var newX = body.position.x
        var newY = body.position.y
        var velX = body.velocity.x
        var velY = body.velocity.y
        var bounced = false
        
        val minX = PhysicsConstants.minX + body.radius
        val maxX = PhysicsConstants.maxX - body.radius
        val minY = PhysicsConstants.minY + body.radius
        val maxY = PhysicsConstants.maxY - body.radius

        if (newX < minX) {
            newX = minX.toFloat()
            velX = Math.abs(velX) * PhysicsConstants.coinCushionRestitution.toFloat()
            bounced = true
        } else if (newX > maxX) {
            newX = maxX.toFloat()
            velX = -Math.abs(velX) * PhysicsConstants.coinCushionRestitution.toFloat()
            bounced = true
        }

        if (newY < minY) {
            newY = minY.toFloat()
            velY = Math.abs(velY) * PhysicsConstants.coinCushionRestitution.toFloat()
            bounced = true
        } else if (newY > maxY) {
            newY = maxY.toFloat()
            velY = -Math.abs(velY) * PhysicsConstants.coinCushionRestitution.toFloat()
            bounced = true
        }

        if (bounced) {
            body.position = Offset(newX, newY)
            body.velocity = Offset(velX, velY)
        }
    }
}

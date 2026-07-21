package com.example.carromaicoach.engine

import androidx.compose.ui.geometry.Offset
import com.example.carromaicoach.data.models.Coin
import com.example.carromaicoach.data.models.DetectionType
import com.example.carromaicoach.data.models.PocketID
import kotlin.math.sqrt

data class PhysicsBody(
    val id: String,
    val bodyType: DetectionType,
    var position: Offset,
    var velocity: Offset,
    val radius: Double,
    val mass: Double,
    var isPocketed: Boolean = false,
    var pocketedIn: PocketID? = null
) {
    val inverseMass: Double = if (mass > 0.0) 1.0 / mass else 0.0
    val isActive: Boolean
        get() = !isPocketed

    val isMoving: Boolean
        get() {
            val lengthSquared = (velocity.x * velocity.x) + (velocity.y * velocity.y)
            return lengthSquared > PhysicsConstants.restThresholdSquared
        }

    val isStriker: Boolean
        get() = bodyType == DetectionType.STRIKER

    fun integrate(deltaTime: Double) {
        if (!isActive || !isMoving) return
        position = Offset(
            x = (position.x + velocity.x * deltaTime).toFloat(),
            y = (position.y + velocity.y * deltaTime).toFloat()
        )
    }

    fun applyFriction(deltaTime: Double) {
        if (!isActive || !isMoving) return

        val speedSquared = (velocity.x * velocity.x) + (velocity.y * velocity.y)
        if (speedSquared <= PhysicsConstants.restThresholdSquared) {
            velocity = Offset.Zero
            return
        }

        val speed = sqrt(speedSquared.toDouble())
        val frictionDeceleration = PhysicsConstants.surfaceFriction * PhysicsConstants.gravity
        val speedDrop = frictionDeceleration * deltaTime

        val multiplier = Math.max(0.0, speed - speedDrop) / speed
        velocity = Offset(
            x = (velocity.x * multiplier).toFloat(),
            y = (velocity.y * multiplier).toFloat()
        )
    }

    companion object {
        fun fromCoin(coin: Coin): PhysicsBody {
            return PhysicsBody(
                id = coin.id,
                bodyType = coin.coinType,
                position = coin.position,
                velocity = coin.velocity,
                radius = coin.physicalRadius,
                mass = coin.mass,
                isPocketed = coin.isPocketed
            )
        }

        fun striker(position: Offset, velocity: Offset): PhysicsBody {
            return PhysicsBody(
                id = "striker",
                bodyType = DetectionType.STRIKER,
                position = position,
                velocity = velocity,
                radius = PhysicsConstants.strikerRadius,
                mass = PhysicsConstants.strikerMass
            )
        }
    }
}

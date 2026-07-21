package com.example.carromaicoach.engine

import androidx.compose.ui.geometry.Offset
import kotlin.math.sqrt

object CollisionResolver {

    fun resolveAll(bodies: MutableList<PhysicsBody>) {
        val n = bodies.size
        for (i in 0 until n) {
            for (j in i + 1 until n) {
                resolvePair(bodies[i], bodies[j])
            }
        }
    }

    private fun resolvePair(a: PhysicsBody, b: PhysicsBody) {
        if (!a.isActive || !b.isActive) return
        if (!a.isMoving && !b.isMoving) return

        val dx = b.position.x - a.position.x
        val dy = b.position.y - a.position.y
        val distSq = (dx * dx) + (dy * dy)

        val minDist = (a.radius + b.radius).toFloat()
        if (distSq >= minDist * minDist) return

        val dist = sqrt(distSq.toDouble()).toFloat()
        if (dist == 0f) return

        // Penetration resolution
        val penetration = minDist - dist
        val totalInverseMass = a.inverseMass + b.inverseMass
        if (totalInverseMass == 0.0) return

        val nx = dx / dist
        val ny = dy / dist

        val correction = penetration / totalInverseMass
        a.position = Offset(
            (a.position.x - nx * correction * a.inverseMass).toFloat(),
            (a.position.y - ny * correction * a.inverseMass).toFloat()
        )
        b.position = Offset(
            (b.position.x + nx * correction * b.inverseMass).toFloat(),
            (b.position.y + ny * correction * b.inverseMass).toFloat()
        )

        // Velocity resolution
        val rvx = b.velocity.x - a.velocity.x
        val rvy = b.velocity.y - a.velocity.y
        val velAlongNormal = rvx * nx + rvy * ny

        if (velAlongNormal > 0) return // Moving apart

        val restitution = if (a.isStriker || b.isStriker) {
            PhysicsConstants.strikerCoinRestitution
        } else {
            PhysicsConstants.coinCoinRestitution
        }

        var j = -(1.0 + restitution) * velAlongNormal
        j /= totalInverseMass

        val impulseX = j * nx
        val impulseY = j * ny

        a.velocity = Offset(
            (a.velocity.x - impulseX * a.inverseMass).toFloat(),
            (a.velocity.y - impulseY * a.inverseMass).toFloat()
        )
        b.velocity = Offset(
            (b.velocity.x + impulseX * b.inverseMass).toFloat(),
            (b.velocity.y + impulseY * b.inverseMass).toFloat()
        )
    }
}

package com.example.carromaicoach.engine

import androidx.compose.ui.geometry.Offset
import com.example.carromaicoach.data.models.Coin
import com.example.carromaicoach.data.models.PocketID
import kotlin.math.cos
import kotlin.math.sin

data class SimulationResult(
    val finalBodies: List<PhysicsBody>,
    val pocketedBodies: List<Pair<String, PocketID>>,
    val strikerPocketed: Boolean,
    val simulationTime: Double,
    val stepCount: Int
)

class PhysicsEngine(
    private val dt: Double = PhysicsConstants.timeStep,
    private val maxTime: Double = PhysicsConstants.maxSimulationTime
) {
    fun simulate(
        bodies: List<PhysicsBody>,
        strikerVelocity: Offset
    ): SimulationResult {
        val simBodies = bodies.map { it.copy() }.toMutableList()
        
        val strikerIndex = simBodies.indexOfFirst { it.isStriker }
        if (strikerIndex != -1) {
            simBodies[strikerIndex].velocity = strikerVelocity
        }

        val pocketed = mutableListOf<Pair<String, PocketID>>()
        var elapsedTime = 0.0
        var stepCount = 0
        val maxSteps = (maxTime / dt).toInt()
        
        for (step in 0 until maxSteps) {
            // 1. Integrate positions
            for (body in simBodies) {
                body.integrate(dt)
            }
            
            // 2. Resolve collisions
            CollisionResolver.resolveAll(simBodies)
            
            // 3. Resolve rebounds and pocketing
            val newlyPocketed = CushionRebound.applyAll(simBodies)
            pocketed.addAll(newlyPocketed)
            
            // 4. Apply friction
            for (body in simBodies) {
                body.applyFriction(dt)
            }
            
            elapsedTime += dt
            stepCount++
            
            val allAtRest = simBodies.all { !it.isMoving || !it.isActive }
            if (allAtRest) break
        }
        
        val strikerPocketed = pocketed.any { it.first == "striker" }
        
        return SimulationResult(
            finalBodies = simBodies,
            pocketedBodies = pocketed,
            strikerPocketed = strikerPocketed,
            simulationTime = elapsedTime,
            stepCount = stepCount
        )
    }

    fun simulateShot(
        coins: List<Coin>,
        strikerPosition: Offset,
        aimAngle: Double,
        power: Double
    ): SimulationResult {
        val bodies = coins
            .filter { it.isInPlay && !it.isStriker }
            .map { PhysicsBody.fromCoin(it) }
            .toMutableList()
            
        val striker = PhysicsBody.striker(position = strikerPosition, velocity = Offset.Zero)
        bodies.add(striker)
        
        val vx = (power * cos(aimAngle)).toFloat()
        val vy = (power * sin(aimAngle)).toFloat()
        val velocity = Offset(vx, vy)
        
        return simulate(bodies, velocity)
    }
}

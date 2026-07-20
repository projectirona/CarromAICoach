// ============================================
// Carrom AI Coach — Physics Engine (JavaScript)
// Port of the Swift PhysicsEngine for the browser simulator
// ============================================

const PhysicsConstants = {
    // Board dimensions (mm) — 52-inch ICF board
    playingAreaDimension: 737.0,
    halfBoard: 737.0 / 2.0,

    // Pocket — real carrom pockets are ~44mm diameter (22mm radius)
    // We use a generous capture zone since coins approaching at angle
    // get funneled in by the pocket cut
    pocketRadius: 22.25,
    pocketCaptureRadius: 32.0,  // Effective capture zone including funnel effect
    pocketCenters: [
        { x: -737/2, y: -737/2 },  // Top-left
        { x:  737/2, y: -737/2 },  // Top-right
        { x: -737/2, y:  737/2 },  // Bottom-left
        { x:  737/2, y:  737/2 },  // Bottom-right
    ],
    pocketNames: ['Top Left', 'Top Right', 'Bottom Left', 'Bottom Right'],
    pocketIDs: ['TL', 'TR', 'BL', 'BR'],

    // Coin/striker dimensions (mm)
    coinRadius: 15.5,
    queenRadius: 15.5,
    strikerRadius: 20.5,  // Physics collision radius (smaller than visual for better gameplay)
    strikerVisualRadius: 37.5, // 75mm diameter striker visual

    // Mass (grams)
    coinMass: 5.0,
    strikerMass: 15.0,

    // Friction — carrom boards are polished and powdered, very low friction
    surfaceFriction: 0.08,

    // Restitution — carrom coins are hard acrylic, quite bouncy
    coinCoinRestitution: 0.90,
    coinCushionRestitution: 0.65,
    strikerCoinRestitution: 0.92,

    // Simulation
    timeStep: 0.0005,       // Smaller step = more accurate collisions
    maxSimulationTime: 5.0,
    restThreshold: 0.3,     // Lower threshold to let coins glide into pockets
    gravity: 9810.0,

    // Power
    minLaunchVelocity: 800,
    maxLaunchVelocity: 6000,

    // Baseline
    baselineOffset: 47.0,
    activeBaseline: 'bottom', // 'bottom' or 'top'
    get baselineY() {
        return this.activeBaseline === 'bottom' 
            ? (737.0 / 2.0 - 47.0) 
            : (-737.0 / 2.0 + 47.0);
    },
    get baselineMinX() { return -this.halfBoard + this.baselineOffset + this.strikerVisualRadius; },
    get baselineMaxX() { return  this.halfBoard - this.baselineOffset - this.strikerVisualRadius; },
};

// ============ Physics Body ============

class PhysicsBody {
    constructor(id, type, x, y, radius, mass) {
        this.id = id;
        this.type = type;  // 'black', 'white', 'queen', 'striker'
        this.x = x;
        this.y = y;
        this.vx = 0;
        this.vy = 0;
        this.radius = radius;
        this.mass = mass;
        this.invMass = mass > 0 ? 1.0 / mass : 0;
        this.isPocketed = false;
        this.pocketedIn = null;
    }

    get isMoving() {
        return (this.vx * this.vx + this.vy * this.vy) >
               (PhysicsConstants.restThreshold * PhysicsConstants.restThreshold);
    }

    get isStriker() { return this.type === 'striker'; }
    get isActive() { return !this.isPocketed; }
    get speed() { return Math.sqrt(this.vx * this.vx + this.vy * this.vy); }

    applyFriction(dt) {
        if (!this.isMoving) { this.vx = 0; this.vy = 0; return; }
        const spd = this.speed;
        const decel = PhysicsConstants.surfaceFriction * PhysicsConstants.gravity;
        const newSpeed = Math.max(0, spd - decel * dt);
        if (newSpeed <= PhysicsConstants.restThreshold) {
            this.vx = 0; this.vy = 0;
        } else {
            const scale = newSpeed / spd;
            this.vx *= scale;
            this.vy *= scale;
        }
    }

    integrate(dt) {
        if (!this.isMoving || !this.isActive) return;
        this.x += this.vx * dt;
        this.y += this.vy * dt;
    }

    checkPocketCapture() {
        const capR = PhysicsConstants.pocketCaptureRadius;
        const capR2 = capR * capR;
        for (let i = 0; i < PhysicsConstants.pocketCenters.length; i++) {
            const p = PhysicsConstants.pocketCenters[i];
            const dx = this.x - p.x, dy = this.y - p.y;
            const distSq = dx * dx + dy * dy;
            if (distSq < capR2) {
                return PhysicsConstants.pocketIDs[i];
            }
        }
        return null;
    }

    clone() {
        const b = new PhysicsBody(this.id, this.type, this.x, this.y, this.radius, this.mass);
        b.vx = this.vx; b.vy = this.vy;
        b.isPocketed = this.isPocketed;
        b.pocketedIn = this.pocketedIn;
        return b;
    }

    static fromCoin(coin) {
        const isStriker = coin.type === 'striker';
        const r = isStriker ? PhysicsConstants.strikerRadius : PhysicsConstants.coinRadius;
        const m = isStriker ? PhysicsConstants.strikerMass : PhysicsConstants.coinMass;
        return new PhysicsBody(coin.id, coin.type, coin.x, coin.y, r, m);
    }

    static createStriker(x, y) {
        return new PhysicsBody('striker', 'striker', x, y,
            PhysicsConstants.strikerRadius, PhysicsConstants.strikerMass);
    }
}

// ============ Collision Resolver ============

function resolveCollision(a, b) {
    if (!a.isActive || !b.isActive) return false;

    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const distSq = dx * dx + dy * dy;
    const minDist = a.radius + b.radius;

    if (distSq >= minDist * minDist || distSq < 0.0001) return false;

    const dist = Math.sqrt(distSq);
    const nx = dx / dist;
    const ny = dy / dist;

    // Separate overlapping
    const overlap = minDist - dist;
    const totalInvMass = a.invMass + b.invMass;
    if (totalInvMass > 0) {
        const sepA = overlap * (a.invMass / totalInvMass);
        const sepB = overlap * (b.invMass / totalInvMass);
        a.x -= nx * sepA; a.y -= ny * sepA;
        b.x += nx * sepB; b.y += ny * sepB;
    }

    // Relative velocity along normal
    const relVelN = (a.vx - b.vx) * nx + (a.vy - b.vy) * ny;
    if (relVelN <= 0) return false;

    // Restitution
    const rest = (a.isStriker || b.isStriker)
        ? PhysicsConstants.strikerCoinRestitution
        : PhysicsConstants.coinCoinRestitution;

    const impulse = -(1 + rest) * relVelN / totalInvMass;
    const ix = impulse * nx;
    const iy = impulse * ny;

    a.vx += ix * a.invMass; a.vy += iy * a.invMass;
    b.vx -= ix * b.invMass; b.vy -= iy * b.invMass;

    return true;
}

function resolveAllCollisions(bodies) {
    // Run multiple iterations for more stable collision resolution
    for (let iter = 0; iter < 2; iter++) {
        for (let i = 0; i < bodies.length - 1; i++) {
            for (let j = i + 1; j < bodies.length; j++) {
                if (bodies[i].isActive && bodies[j].isActive) {
                    resolveCollision(bodies[i], bodies[j]);
                }
            }
        }
    }
}

// ============ Cushion Rebound ============

function applyCushionRebound(body) {
    if (!body.isActive) return null;

    // Check pocket first — pockets are cut into corners so coins near
    // a corner get captured even before hitting the cushion
    const pocketID = body.checkPocketCapture();
    if (pocketID) {
        body.isPocketed = true;
        body.pocketedIn = pocketID;
        body.vx = 0; body.vy = 0;
        return pocketID;
    }

    const half = PhysicsConstants.halfBoard;
    const rest = PhysicsConstants.coinCushionRestitution;
    let bounced = false;

    if (body.x - body.radius < -half) {
        body.x = -half + body.radius;
        body.vx = -body.vx * rest;
        bounced = true;
    }
    if (body.x + body.radius > half) {
        body.x = half - body.radius;
        body.vx = -body.vx * rest;
        bounced = true;
    }
    if (body.y - body.radius < -half) {
        body.y = -half + body.radius;
        body.vy = -body.vy * rest;
        bounced = true;
    }
    if (body.y + body.radius > half) {
        body.y = half - body.radius;
        body.vy = -body.vy * rest;
        bounced = true;
    }

    if (bounced) {
        const pID = body.checkPocketCapture();
        if (pID) {
            body.isPocketed = true;
            body.pocketedIn = pID;
            body.vx = 0; body.vy = 0;
            return pID;
        }
    }
    return null;
}

// ============ Physics Engine ============

class PhysicsEngine {
    constructor() {
        this.dt = PhysicsConstants.timeStep;
        this.maxTime = PhysicsConstants.maxSimulationTime;
    }

    simulate(bodies, strikerVx, strikerVy) {
        // Clone bodies
        const sim = bodies.map(b => b.clone());

        // Launch striker
        const striker = sim.find(b => b.isStriker);
        if (striker) { striker.vx = strikerVx; striker.vy = strikerVy; }

        const pocketed = [];
        let elapsed = 0;
        let steps = 0;
        const maxSteps = Math.ceil(this.maxTime / this.dt);

        // Record positions for animation
        const trajectories = {};
        sim.forEach(b => { trajectories[b.id] = [{ x: b.x, y: b.y }]; });

        const recordInterval = 20; // Record every 20 steps for smooth animation

        for (let s = 0; s < maxSteps; s++) {
            // Integrate
            for (const b of sim) b.integrate(this.dt);

            // Collisions
            resolveAllCollisions(sim);

            // Cushion + pocket
            for (const b of sim) {
                if (!b.isActive) continue;
                const pID = applyCushionRebound(b);
                if (pID) pocketed.push({ bodyID: b.id, pocketID: pID, type: b.type });
            }

            // Friction
            for (const b of sim) b.applyFriction(this.dt);

            // Record for animation
            if (s % recordInterval === 0) {
                sim.forEach(b => {
                    if (trajectories[b.id]) {
                        trajectories[b.id].push({ x: b.x, y: b.y, pocketed: b.isPocketed });
                    }
                });
            }

            elapsed += this.dt;
            steps++;

            // All at rest?
            if (sim.every(b => !b.isMoving || !b.isActive)) break;
        }

        // Final positions
        sim.forEach(b => {
            if (trajectories[b.id]) {
                trajectories[b.id].push({ x: b.x, y: b.y, pocketed: b.isPocketed });
            }
        });

        const strikerPocketed = pocketed.some(p => p.bodyID === 'striker');

        return {
            finalBodies: sim,
            pocketed,
            strikerPocketed,
            simulationTime: elapsed,
            stepCount: steps,
            trajectories,
            pocketedCoinCount: pocketed.filter(p => p.bodyID !== 'striker').length,
        };
    }

    simulateShot(coins, strikerX, strikerY, aimAngle, power) {
        const bodies = coins
            .filter(c => !c.isPocketed && c.type !== 'striker')
            .map(c => PhysicsBody.fromCoin(c));

        bodies.push(PhysicsBody.createStriker(strikerX, strikerY));

        const vx = Math.cos(aimAngle) * power;
        const vy = Math.sin(aimAngle) * power;

        return this.simulate(bodies, vx, vy);
    }
}

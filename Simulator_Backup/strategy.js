// ============================================
// Carrom AI Coach — Strategy Engine (JavaScript)
// Port of the Swift ShotGenerator, ShotEvaluator, StrategyEngine
// ============================================

// ============ Score Weights ============

const ScoreWeights = {
    pocketProbability: 0.35,
    easeOfExecution: 0.15,
    futurePosition: 0.10,
    queenOpportunity: 0.10,
    coverOpportunity: 0.05,
    foulRisk: 0.10,
    unblockPotential: 0.05,
    opponentAdvantage: 0.10,
};

// ============ Shot Generator ============

class ShotGenerator {
    constructor(sampleCount = 40) {
        this.sampleCount = sampleCount;
        this.pockets = PhysicsConstants.pocketCenters.map((p, i) => ({
            x: p.x, y: p.y,
            id: PhysicsConstants.pocketIDs[i],
            name: PhysicsConstants.pocketNames[i],
        }));
    }

    generateCandidates(coins, playerColor, includeQueen = true) {
        const candidates = [];

        // Target coins: player's coins + queen
        const targets = coins.filter(c =>
            !c.isPocketed && (
                c.type === playerColor ||
                (includeQueen && c.type === 'queen')
            )
        );

        if (targets.length === 0) return candidates;

        const strikerPositions = this._sampleBaseline();
        const allActive = coins.filter(c => !c.isPocketed && c.type !== 'striker');

        for (const target of targets) {
            for (const pocket of this.pockets) {
                // Pre-check: is the coin-to-pocket path clear of other coins?
                const coinToPocketClear = this._hasCoinToPocketLOS(
                    target.x, target.y, pocket.x, pocket.y, target.id, allActive
                );

                // Direct shots
                const directShots = this._generateDirectShots(
                    target, pocket, strikerPositions, allActive, coinToPocketClear
                );
                candidates.push(...directShots);

                // Single rebound shots (only if coin-to-pocket is clear)
                if (coinToPocketClear) {
                    const reboundShots = this._generateReboundShots(
                        target, pocket, strikerPositions, allActive
                    );
                    candidates.push(...reboundShots);
                }
            }
        }

        return candidates;
    }

    _sampleBaseline() {
        const positions = [];
        const minX = PhysicsConstants.baselineMinX;
        const maxX = PhysicsConstants.baselineMaxX;
        const y = PhysicsConstants.baselineY;
        const step = (maxX - minX) / (this.sampleCount - 1);

        for (let i = 0; i < this.sampleCount; i++) {
            positions.push({ x: minX + step * i, y: y });
        }
        return positions;
    }

    _generateDirectShots(target, pocket, strikerPositions, allCoins, coinToPocketClear) {
        const shots = [];
        const coinPos = { x: target.x, y: target.y };
        const pocketPos = { x: pocket.x, y: pocket.y };

        // Direction coin → pocket
        const c2pDx = pocketPos.x - coinPos.x;
        const c2pDy = pocketPos.y - coinPos.y;
        const c2pLen = Math.sqrt(c2pDx * c2pDx + c2pDy * c2pDy);
        if (c2pLen < 1) return shots;

        const c2pNx = c2pDx / c2pLen;
        const c2pNy = c2pDy / c2pLen;

        // Aim point: opposite side of coin from pocket direction
        // Use the physics collision radius for contact distance
        const contactDist = target.radius + PhysicsConstants.strikerRadius;
        const aimX = coinPos.x - c2pNx * contactDist;
        const aimY = coinPos.y - c2pNy * contactDist;

        for (const sp of strikerPositions) {
            const sDx = aimX - sp.x;
            const sDy = aimY - sp.y;
            const dist = Math.sqrt(sDx * sDx + sDy * sDy);

            if (dist < PhysicsConstants.strikerRadius + target.radius) continue;

            // Line of sight check (striker to aim point)
            if (!this._hasLineOfSight(sp.x, sp.y, aimX, aimY, target.id, allCoins)) continue;

            const angle = Math.atan2(sDy, sDx);

            // Multiple power levels for each shot to find optimal power
            const powers = this._estimatePowers(dist, c2pLen, 0);

            for (const power of powers) {
                // Geometric quality score for pre-sorting
                const geoScore = this._geometricScore(
                    sp, { x: aimX, y: aimY }, coinPos, pocketPos,
                    dist, c2pLen, coinToPocketClear, 0
                );

                shots.push({
                    strikerX: sp.x, strikerY: sp.y,
                    aimAngle: angle, power,
                    targetCoin: target, targetPocket: pocket,
                    shotType: 'Direct', rebounds: 0,
                    strikerPath: [{ x: sp.x, y: sp.y }, { x: aimX, y: aimY }],
                    coinPath: [{ x: coinPos.x, y: coinPos.y }, { x: pocketPos.x, y: pocketPos.y }],
                    geoScore,
                });
            }
        }

        return shots;
    }

    _generateReboundShots(target, pocket, strikerPositions, allCoins) {
        const shots = [];
        const half = PhysicsConstants.halfBoard;
        const coinPos = { x: target.x, y: target.y };
        const pocketPos = { x: pocket.x, y: pocket.y };

        const c2pDx = pocketPos.x - coinPos.x;
        const c2pDy = pocketPos.y - coinPos.y;
        const c2pLen = Math.sqrt(c2pDx * c2pDx + c2pDy * c2pDy);
        if (c2pLen < 1) return shots;

        const c2pNx = c2pDx / c2pLen;
        const c2pNy = c2pDy / c2pLen;

        const contactDist = target.radius + PhysicsConstants.strikerRadius;
        const aimX = coinPos.x - c2pNx * contactDist;
        const aimY = coinPos.y - c2pNy * contactDist;

        // 4 cushions: top, bottom, left, right
        const cushions = [
            { axis: 'h', wall: -half }, // top
            { axis: 'h', wall:  half }, // bottom
            { axis: 'v', wall: -half }, // left
            { axis: 'v', wall:  half }, // right
        ];

        for (const cushion of cushions) {
            // Mirror aim point across cushion
            let mirrorX, mirrorY;
            if (cushion.axis === 'h') {
                mirrorX = aimX;
                mirrorY = 2 * cushion.wall - aimY;
            } else {
                mirrorX = 2 * cushion.wall - aimX;
                mirrorY = aimY;
            }

            for (const sp of strikerPositions) {
                const sDx = mirrorX - sp.x;
                const sDy = mirrorY - sp.y;
                const angle = Math.atan2(sDy, sDx);

                // Rebound point on cushion
                let reboundX, reboundY;
                if (cushion.axis === 'h') {
                    const t = (cushion.wall - sp.y) / (mirrorY - sp.y);
                    if (t <= 0 || t >= 1) continue;
                    reboundX = sp.x + t * (mirrorX - sp.x);
                    reboundY = cushion.wall;
                } else {
                    const t = (cushion.wall - sp.x) / (mirrorX - sp.x);
                    if (t <= 0 || t >= 1) continue;
                    reboundX = cushion.wall;
                    reboundY = sp.y + t * (mirrorY - sp.y);
                }

                if (Math.abs(reboundX) > half || Math.abs(reboundY) > half) continue;

                // Check if rebound point is near a pocket (would get captured)
                let nearPocket = false;
                for (const pc of PhysicsConstants.pocketCenters) {
                    const pdx = reboundX - pc.x, pdy = reboundY - pc.y;
                    if (Math.sqrt(pdx * pdx + pdy * pdy) < PhysicsConstants.pocketCaptureRadius * 1.5) {
                        nearPocket = true;
                        break;
                    }
                }
                if (nearPocket) continue;

                const d1 = Math.sqrt((reboundX - sp.x) ** 2 + (reboundY - sp.y) ** 2);
                const d2 = Math.sqrt((aimX - reboundX) ** 2 + (aimY - reboundY) ** 2);
                const totalDist = d1 + d2;

                const powers = this._estimatePowers(totalDist, c2pLen, 1);

                for (const power of powers) {
                    const geoScore = this._geometricScore(
                        sp, { x: aimX, y: aimY }, coinPos, pocketPos,
                        totalDist, c2pLen, true, 1
                    );

                    shots.push({
                        strikerX: sp.x, strikerY: sp.y,
                        aimAngle: angle, power,
                        targetCoin: target, targetPocket: pocket,
                        shotType: 'Rebound', rebounds: 1,
                        strikerPath: [
                            { x: sp.x, y: sp.y },
                            { x: reboundX, y: reboundY },
                            { x: aimX, y: aimY }
                        ],
                        coinPath: [
                            { x: coinPos.x, y: coinPos.y },
                            { x: pocketPos.x, y: pocketPos.y }
                        ],
                        geoScore,
                    });
                }
            }
        }

        return shots;
    }

    // Check if the coin-to-pocket path is clear (no other coins blocking)
    _hasCoinToPocketLOS(fromX, fromY, toX, toY, excludeID, allCoins) {
        const dx = toX - fromX;
        const dy = toY - fromY;
        const len = Math.sqrt(dx * dx + dy * dy);
        if (len < 1) return true;

        const ndx = dx / len;
        const ndy = dy / len;

        for (const coin of allCoins) {
            if (coin.id === excludeID || coin.isPocketed) continue;

            const toCoinX = coin.x - fromX;
            const toCoinY = coin.y - fromY;
            const proj = toCoinX * ndx + toCoinY * ndy;

            if (proj <= coin.radius || proj >= len) continue;

            const perpX = toCoinX - proj * ndx;
            const perpY = toCoinY - proj * ndy;
            const perpDist = Math.sqrt(perpX * perpX + perpY * perpY);

            // Use coin radius * 2 for clearance (two coins can't overlap)
            const clearance = PhysicsConstants.coinRadius * 2.2;
            if (perpDist < clearance) return false;
        }
        return true;
    }

    _hasLineOfSight(fromX, fromY, toX, toY, excludeID, allCoins) {
        const dx = toX - fromX;
        const dy = toY - fromY;
        const len = Math.sqrt(dx * dx + dy * dy);
        if (len < 1) return true;

        const ndx = dx / len;
        const ndy = dy / len;

        for (const coin of allCoins) {
            if (coin.id === excludeID || coin.isPocketed) continue;

            const toCoinX = coin.x - fromX;
            const toCoinY = coin.y - fromY;
            const proj = toCoinX * ndx + toCoinY * ndy;

            if (proj <= 0 || proj >= len) continue;

            const perpX = toCoinX - proj * ndx;
            const perpY = toCoinY - proj * ndy;
            const perpDist = Math.sqrt(perpX * perpX + perpY * perpY);

            const clearance = PhysicsConstants.strikerRadius + coin.radius;
            if (perpDist < clearance) return false;
        }
        return true;
    }

    // Generate multiple power levels to find optimal
    _estimatePowers(strikerDist, coinDist, rebounds) {
        const total = strikerDist + coinDist;
        const frictionLoss = PhysicsConstants.surfaceFriction * PhysicsConstants.gravity;
        const minV = Math.sqrt(2 * frictionLoss * total);
        const rebMult = 1 + rebounds * (1 - PhysicsConstants.coinCushionRestitution);

        // Base estimate with generous multiplier
        const base = minV * rebMult * 2.5;

        // Return 3 power levels: medium, strong, gentle
        return [
            Math.min(Math.max(base, PhysicsConstants.minLaunchVelocity), PhysicsConstants.maxLaunchVelocity),
            Math.min(Math.max(base * 1.4, PhysicsConstants.minLaunchVelocity), PhysicsConstants.maxLaunchVelocity),
            Math.min(Math.max(base * 0.7, PhysicsConstants.minLaunchVelocity), PhysicsConstants.maxLaunchVelocity),
        ];
    }

    // Geometric quality score for pre-sorting candidates (higher = better)
    _geometricScore(strikerPos, aimPos, coinPos, pocketPos, strikerDist, coinToPocketDist, coinToPocketClear, rebounds) {
        let score = 0;

        // Reward short striker distances (easier to aim)
        score += Math.max(0, 1 - strikerDist / (PhysicsConstants.playingAreaDimension * 1.5)) * 30;

        // Reward short coin-to-pocket distances
        score += Math.max(0, 1 - coinToPocketDist / (PhysicsConstants.playingAreaDimension * 1.5)) * 25;

        // Reward clear coin-to-pocket path
        if (coinToPocketClear) score += 20;

        // Penalize rebounds
        score -= rebounds * 15;

        // Reward direct alignment — angle between striker→coin and coin→pocket
        const s2cDx = coinPos.x - strikerPos.x;
        const s2cDy = coinPos.y - strikerPos.y;
        const c2pDx = pocketPos.x - coinPos.x;
        const c2pDy = pocketPos.y - coinPos.y;
        const s2cLen = Math.sqrt(s2cDx * s2cDx + s2cDy * s2cDy);
        const c2pLen = Math.sqrt(c2pDx * c2pDx + c2pDy * c2pDy);
        if (s2cLen > 0 && c2pLen > 0) {
            const dot = (s2cDx / s2cLen) * (c2pDx / c2pLen) + (s2cDy / s2cLen) * (c2pDy / c2pLen);
            // dot ≈ 1 means perfectly aligned (striker, coin, pocket in a line)
            score += Math.max(0, dot) * 25;
        }

        return score;
    }
}

// ============ Shot Evaluator ============

class ShotEvaluator {
    constructor() {
        this.physicsEngine = new PhysicsEngine();
    }

    evaluate(candidate, coins, playerColor, matchState) {
        // Run physics simulation
        const simResult = this.physicsEngine.simulateShot(
            coins, candidate.strikerX, candidate.strikerY,
            candidate.aimAngle, candidate.power
        );

        const scores = {
            pocketProbability: this._scorePocketProb(candidate, simResult),
            easeOfExecution: this._scoreEase(candidate),
            futurePosition: this._scoreFuturePos(simResult, playerColor),
            queenOpportunity: this._scoreQueen(candidate, simResult, matchState),
            coverOpportunity: this._scoreCover(simResult, matchState, playerColor),
            foulRisk: simResult.strikerPocketed ? 0 : 1,
            unblockPotential: 0.5,
            opponentAdvantage: this._scoreOpponent(simResult, playerColor),
        };

        const composite =
            scores.pocketProbability * ScoreWeights.pocketProbability +
            scores.easeOfExecution * ScoreWeights.easeOfExecution +
            scores.futurePosition * ScoreWeights.futurePosition +
            scores.queenOpportunity * ScoreWeights.queenOpportunity +
            scores.coverOpportunity * ScoreWeights.coverOpportunity +
            scores.foulRisk * ScoreWeights.foulRisk +
            scores.unblockPotential * ScoreWeights.unblockPotential +
            scores.opponentAdvantage * ScoreWeights.opponentAdvantage;

        return { candidate, scores, composite, simResult };
    }

    _scorePocketProb(candidate, simResult) {
        // Check if the target coin was pocketed in the target pocket
        const targetPocketed = simResult.pocketed.some(
            p => p.bodyID === candidate.targetCoin.id && p.pocketID === candidate.targetPocket.id
        );
        if (targetPocketed) {
            // Bonus for pocketing additional coins
            return Math.min(1.0, 0.95 + (simResult.pocketedCoinCount - 1) * 0.05);
        }

        // Check if pocketed in any pocket (still good, just not the intended one)
        const anyPocketed = simResult.pocketed.some(p => p.bodyID === candidate.targetCoin.id);
        if (anyPocketed) {
            return 0.7;
        }

        // Partial credit based on how close the coin got to the target pocket
        const finalBody = simResult.finalBodies.find(b => b.id === candidate.targetCoin.id);
        if (finalBody) {
            const dx = finalBody.x - candidate.targetPocket.x;
            const dy = finalBody.y - candidate.targetPocket.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            const maxDist = PhysicsConstants.playingAreaDimension * 0.7;
            return Math.max(0, (1 - dist / maxDist)) * 0.25;
        }
        return 0;
    }

    _scoreEase(candidate) {
        const typePenalty = candidate.shotType === 'Direct' ? 1.0 :
                            candidate.shotType === 'Rebound' ? 0.6 : 0.35;
        let pathLen = 0;
        for (let i = 1; i < candidate.strikerPath.length; i++) {
            const dx = candidate.strikerPath[i].x - candidate.strikerPath[i-1].x;
            const dy = candidate.strikerPath[i].y - candidate.strikerPath[i-1].y;
            pathLen += Math.sqrt(dx*dx + dy*dy);
        }
        const distFactor = Math.max(0, 1 - pathLen / (PhysicsConstants.playingAreaDimension * 2));
        return typePenalty * 0.6 + distFactor * 0.4;
    }

    _scoreFuturePos(simResult, playerColor) {
        const playerBodies = simResult.finalBodies.filter(
            b => !b.isPocketed && !b.isStriker && b.type === playerColor
        );
        if (playerBodies.length === 0) return 1.0;

        let score = 0.5;
        for (const body of playerBodies) {
            let minDist = Infinity;
            for (const p of PhysicsConstants.pocketCenters) {
                const dx = body.x - p.x, dy = body.y - p.y;
                minDist = Math.min(minDist, Math.sqrt(dx*dx + dy*dy));
            }
            score += (1 - minDist / PhysicsConstants.playingAreaDimension) * 0.1;
        }
        return Math.min(1, Math.max(0, score));
    }

    _scoreQueen(candidate, simResult, matchState) {
        if (matchState.queenStatus !== 'onBoard') return 0.5;
        const queenPocketed = simResult.pocketed.some(p => p.type === 'queen');
        if (candidate.targetCoin.type === 'queen') return queenPocketed ? 1.0 : 0.3;
        return queenPocketed ? 0.8 : 0.5;
    }

    _scoreCover(simResult, matchState, playerColor) {
        if (matchState.queenStatus !== 'pocketed') return 0.5;
        const playerPocketed = simResult.pocketed.some(p => p.type === playerColor);
        return playerPocketed ? 1.0 : 0.0;
    }

    _scoreOpponent(simResult, playerColor) {
        const opponentColor = playerColor === 'black' ? 'white' : 'black';
        const opponentPocketed = simResult.pocketed.some(
            p => p.type === opponentColor
        );
        // Penalize shots that accidentally pocket opponent coins
        if (opponentPocketed) return 0.2;

        const opponentBodies = simResult.finalBodies.filter(
            b => !b.isPocketed && !b.isStriker && b.type === opponentColor
        );
        let nearCount = 0;
        for (const body of opponentBodies) {
            for (const p of PhysicsConstants.pocketCenters) {
                const dx = body.x - p.x, dy = body.y - p.y;
                if (Math.sqrt(dx*dx + dy*dy) < 100) { nearCount++; break; }
            }
        }
        return 1 - nearCount / Math.max(1, opponentBodies.length + nearCount);
    }
}

// ============ Strategy Engine ============

class StrategyEngine {
    constructor() {
        this.shotGenerator = new ShotGenerator(40);
        this.shotEvaluator = new ShotEvaluator();
        this.maxAnalysisTime = 3000; // ms — allow more time for thorough analysis
    }

    analyze(coins, playerColor, matchState) {
        const startTime = performance.now();

        const includeQueen = matchState.queenStatus === 'onBoard' &&
            coins.filter(c => c.type === playerColor && !c.isPocketed).length >= 2;

        const candidates = this.shotGenerator.generateCandidates(coins, playerColor, includeQueen);

        if (candidates.length === 0) return null;

        // Sort candidates by geometric quality (best first) for smarter evaluation order
        candidates.sort((a, b) => b.geoScore - a.geoScore);

        // Deduplicate similar candidates (same target, same pocket, very close position)
        const filtered = this._deduplicateCandidates(candidates);

        const evaluated = [];
        let bestComposite = -Infinity;

        for (const candidate of filtered) {
            if (performance.now() - startTime > this.maxAnalysisTime) break;

            const result = this.shotEvaluator.evaluate(candidate, coins, playerColor, matchState);
            evaluated.push(result);

            if (result.composite > bestComposite) {
                bestComposite = result.composite;
            }
        }

        if (evaluated.length === 0) return null;

        evaluated.sort((a, b) => b.composite - a.composite);

        const best = evaluated[0];
        const analysisTime = performance.now() - startTime;

        // Collect pocketable coins (unique coin+pocket combinations where shot actually pockets)
        const pocketableSet = new Set();
        const pocketable = [];
        for (const shot of evaluated) {
            const targetPocketed = shot.simResult.pocketed.some(
                p => p.bodyID === shot.candidate.targetCoin.id
            );
            if (targetPocketed) {
                const coinId = shot.candidate.targetCoin.id;
                if (!pocketableSet.has(coinId)) {
                    pocketableSet.add(coinId);
                    pocketable.push({
                        coin: shot.candidate.targetCoin,
                        pocket: shot.candidate.targetPocket,
                        prob: shot.scores.pocketProbability,
                        shotType: shot.candidate.shotType,
                    });
                }
            }
        }

        pocketable.sort((a, b) => b.prob - a.prob);

        // Collect top alternative shots (different from best)
        const alternatives = evaluated.slice(1, 4).map(shot => ({
            target: shot.candidate.targetCoin.type,
            pocket: shot.candidate.targetPocket.name,
            shotType: shot.candidate.shotType,
            probability: Math.round(shot.scores.pocketProbability * 100),
            composite: shot.composite,
        }));

        // Reasoning
        const probPct = Math.round(best.scores.pocketProbability * 100);
        const reasoning = `${best.candidate.shotType} shot targeting ${best.candidate.targetCoin.type} coin ` +
            `to ${best.candidate.targetPocket.name} pocket ` +
            `(${probPct}% success). ` +
            `${evaluated.length}/${candidates.length} shots analyzed in ${(analysisTime / 1000).toFixed(2)}s.` +
            (best.scores.foulRisk < 0.5 ? ' ⚠ Watch for foul risk.' : '') +
            (best.scores.queenOpportunity > 0.7 ? ' 👑 Queen opportunity!' : '') +
            (pocketable.length > 0 ? ` ${pocketable.length} pocketable coin(s) found.` : '');

        return {
            bestShot: best,
            alternatives,
            pocketable,
            reasoning,
            analysisTime,
            totalCandidates: candidates.length,
            evaluatedCandidates: evaluated.length,
        };
    }

    _deduplicateCandidates(candidates) {
        const seen = new Map(); // key → best geoScore candidate
        const result = [];

        for (const c of candidates) {
            // Key: target coin + target pocket + rough striker position (bucketized to 30mm)
            const bucketX = Math.round(c.strikerX / 30);
            const key = `${c.targetCoin.id}_${c.targetPocket.id}_${bucketX}_${c.shotType}_${Math.round(c.power / 200)}`;

            if (!seen.has(key)) {
                seen.set(key, true);
                result.push(c);
            }
        }

        return result;
    }
}

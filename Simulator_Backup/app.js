// ============================================
// Carrom AI Coach — Application Controller
// Main application logic coordinating UI, physics, and strategy
// ============================================

// ============ State ============

let appState = {
    playerColor: null,
    currentScreen: 'colorSelect',
    turn: 1,
    coins: [],
    matchState: {
        queenStatus: 'onBoard', // 'onBoard', 'pocketed', 'covered'
        remainingPlayer: 9,
        remainingOpponent: 9,
    },
    currentRecommendation: null,
    shotHistory: [],
};

let renderer;
let strategyEngine;

// Drag state
let dragCoin = null;

// ============ Initialization ============

window.addEventListener('DOMContentLoaded', () => {
    renderer = new BoardRenderer('board-canvas');
    strategyEngine = new StrategyEngine();

    // Hook up canvas events for dragging coins
    const canvas = document.getElementById('board-canvas');
    canvas.addEventListener('mousedown', handleMouseDown);
    canvas.addEventListener('mousemove', handleMouseMove);
    canvas.addEventListener('mouseup', handleMouseUp);

    canvas.addEventListener('touchstart', handleTouchStart, { passive: false });
    canvas.addEventListener('touchmove', handleTouchMove, { passive: false });
    canvas.addEventListener('touchend', handleTouchEnd);

    // Keyboard shortcuts
    window.addEventListener('keydown', handleKeyDown);
});

// ============ Keyboard Shortcuts ============

function handleKeyDown(e) {
    if (appState.currentScreen !== 'game') return;

    if (e.key === 'a' || e.key === 'A') {
        analyzeBoard();
    } else if (e.key === 'p' || e.key === 'P') {
        const btnPlay = document.getElementById('btn-play-shot');
        if (!btnPlay.disabled) playShot();
    } else if (e.key === 'r' || e.key === 'R') {
        randomizeBoard();
    } else if (e.key === 'n' || e.key === 'N') {
        newMatch();
    }
}

// ============ Interactive Dragging ============

function getCanvasCoords(e, canvas) {
    const rect = canvas.getBoundingClientRect();
    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
    const clientY = e.touches ? e.touches[0].clientY : e.clientY;
    return {
        x: ((clientX - rect.left) / rect.width) * canvas.width,
        y: ((clientY - rect.top) / rect.height) * canvas.height
    };
}

function handleMouseDown(e) {
    if (renderer.animating) return;
    const coords = getCanvasCoords(e, renderer.canvas);
    const boardPos = renderer.toBoard(coords.x, coords.y);

    // Find clicked active coin
    for (const coin of appState.coins) {
        if (coin.isPocketed) continue;
        const dx = coin.x - boardPos.x;
        const dy = coin.y - boardPos.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist <= (coin.radius || PhysicsConstants.coinRadius) * 1.5) {
            dragCoin = coin;
            break;
        }
    }
}

function handleMouseMove(e) {
    if (!dragCoin) return;
    const coords = getCanvasCoords(e, renderer.canvas);
    const boardPos = renderer.toBoard(coords.x, coords.y);

    // Constrain within playable board limits
    const maxLimit = PhysicsConstants.halfBoard - dragCoin.radius - 20;
    dragCoin.x = Math.max(-maxLimit, Math.min(maxLimit, boardPos.x));
    dragCoin.y = Math.max(-maxLimit, Math.min(maxLimit, boardPos.y));

    // Clear recommendation and redraw board
    appState.currentRecommendation = null;
    document.getElementById('recommendation-card').classList.add('hidden');
    document.getElementById('perf-card').classList.add('hidden');
    document.getElementById('alternatives-card').classList.add('hidden');
    document.getElementById('btn-play-shot').disabled = true;

    renderer.drawBoard(appState.coins);
}

function handleMouseUp(e) {
    if (dragCoin) {
        dragCoin = null;
        updateBoardState();
    }
}

function handleTouchStart(e) {
    if (renderer.animating) return;
    handleMouseDown(e);
    if (dragCoin) e.preventDefault();
}

function handleTouchMove(e) {
    if (!dragCoin) return;
    handleMouseMove(e);
    e.preventDefault();
}

function handleTouchEnd(e) {
    handleMouseUp(e);
}

// ============ active Baseline Toggle ============

function changeBaseline(side) {
    PhysicsConstants.activeBaseline = side;
    
    // Clear recommendation as striker positioning baseline changed
    appState.currentRecommendation = null;
    document.getElementById('recommendation-card').classList.add('hidden');
    document.getElementById('perf-card').classList.add('hidden');
    document.getElementById('alternatives-card').classList.add('hidden');
    document.getElementById('btn-play-shot').disabled = true;

    renderer.drawBoard(appState.coins);
}

// ============ Import / Export State ============

function exportBoardState() {
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(appState.coins));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute("href", dataStr);
    downloadAnchor.setAttribute("download", `carrom_board_state_turn_${appState.turn}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
}

function importBoardState() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    input.onchange = e => {
        const file = e.target.files[0];
        const reader = new FileReader();
        reader.onload = readerEvent => {
            try {
                const parsed = JSON.parse(readerEvent.target.result);
                if (Array.isArray(parsed) && parsed.length > 0) {
                    appState.coins = parsed;
                    appState.currentRecommendation = null;
                    document.getElementById('recommendation-card').classList.add('hidden');
                    document.getElementById('perf-card').classList.add('hidden');
                    document.getElementById('alternatives-card').classList.add('hidden');
                    document.getElementById('btn-play-shot').disabled = true;

                    updateBoardState();
                    renderer.drawBoard(appState.coins);
                } else {
                    alert('Invalid board state file');
                }
            } catch (err) {
                alert('Failed to parse JSON file');
            }
        };
        reader.readAsText(file);
    };
    input.click();
}

// ============ Screen Navigation ============

function showScreen(screenId) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(`screen-${screenId}`).classList.add('active');
    appState.currentScreen = screenId;
}

function selectColor(color) {
    appState.playerColor = color;
    appState.turn = 1;
    appState.shotHistory = [];
    appState.matchState = {
        queenStatus: 'onBoard',
        remainingPlayer: 9,
        remainingOpponent: 9,
    };

    // Update UI
    const indicator = document.getElementById('player-color-indicator');
    indicator.className = `player-indicator ${color}`;
    document.getElementById('player-color-label').textContent = color.charAt(0).toUpperCase() + color.slice(1);
    document.getElementById('turn-label').textContent = `Turn ${appState.turn}`;
    document.getElementById('match-info').classList.remove('hidden');

    showScreen('game');

    // Generate initial board
    generateInitialBoard();
    renderer.drawBoard(appState.coins);
    updateBoardState();
}

function newMatch() {
    appState.currentRecommendation = null;
    document.getElementById('recommendation-card').classList.add('hidden');
    document.getElementById('perf-card').classList.add('hidden');
    document.getElementById('alternatives-card').classList.add('hidden');
    document.getElementById('btn-play-shot').disabled = true;
    document.getElementById('shot-history').innerHTML = '<div class="empty-history">No shots yet</div>';
    showScreen('color-select');
}

// ============ Board Generation ============

function generateInitialBoard() {
    appState.coins = [];

    // Standard opening arrangement: coins in center circle
    const centerR = 55; // mm from center

    // 6 inner coins, alternating B/W
    for (let i = 0; i < 6; i++) {
        const angle = (Math.PI / 3) * i;
        const x = Math.cos(angle) * centerR;
        const y = Math.sin(angle) * centerR;
        const type = i % 2 === 0 ? 'white' : 'black';
        appState.coins.push({
            id: `${type}_${Math.floor(i/2)}`,
            type, x, y,
            radius: PhysicsConstants.coinRadius,
            isPocketed: false,
        });
    }

    // 6 outer coins
    for (let i = 0; i < 6; i++) {
        const angle = (Math.PI / 3) * i + Math.PI / 6;
        const x = Math.cos(angle) * centerR * 1.7;
        const y = Math.sin(angle) * centerR * 1.7;
        const type = i % 2 === 0 ? 'black' : 'white';
        const idx = 3 + Math.floor(i / 2);
        appState.coins.push({
            id: `${type}_${idx}`,
            type, x, y,
            radius: PhysicsConstants.coinRadius,
            isPocketed: false,
        });
    }

    // Remaining coins scattered
    const remaining = [
        { type: 'black', id: 'black_6', x: -120, y: -100 },
        { type: 'black', id: 'black_7', x: 90, y: -140 },
        { type: 'black', id: 'black_8', x: 150, y: 80 },
        { type: 'white', id: 'white_6', x: 130, y: -90 },
        { type: 'white', id: 'white_7', x: -140, y: 110 },
        { type: 'white', id: 'white_8', x: -80, y: -160 },
    ];
    for (const c of remaining) {
        appState.coins.push({
            ...c,
            radius: PhysicsConstants.coinRadius,
            isPocketed: false,
        });
    }

    // Queen at center
    appState.coins.push({
        id: 'queen', type: 'queen',
        x: 0, y: 0,
        radius: PhysicsConstants.queenRadius,
        isPocketed: false,
    });
}

function randomizeBoard() {
    appState.coins = [];
    appState.currentRecommendation = null;
    document.getElementById('recommendation-card').classList.add('hidden');
    document.getElementById('perf-card').classList.add('hidden');
    document.getElementById('alternatives-card').classList.add('hidden');
    document.getElementById('btn-play-shot').disabled = true;

    const half = PhysicsConstants.halfBoard;
    const margin = 60;
    const placed = [];

    function randomPos() {
        const x = (Math.random() - 0.5) * (half * 2 - margin * 2);
        const y = (Math.random() - 0.5) * (half * 2 - margin * 2);
        return { x, y };
    }

    function isOverlapping(x, y, r) {
        for (const p of placed) {
            const dx = p.x - x, dy = p.y - y;
            if (Math.sqrt(dx * dx + dy * dy) < p.r + r + 5) return true;
        }
        // Check pockets
        for (const pocket of PhysicsConstants.pocketCenters) {
            const dx = pocket.x - x, dy = pocket.y - y;
            if (Math.sqrt(dx * dx + dy * dy) < PhysicsConstants.pocketCaptureRadius + r + 10) return true;
        }
        return false;
    }

    function placeRandom(id, type, r) {
        for (let attempt = 0; attempt < 100; attempt++) {
            const pos = randomPos();
            if (!isOverlapping(pos.x, pos.y, r)) {
                placed.push({ x: pos.x, y: pos.y, r });
                return { id, type, x: pos.x, y: pos.y, radius: r, isPocketed: false };
            }
        }
        // Fallback
        const pos = randomPos();
        placed.push({ x: pos.x, y: pos.y, r });
        return { id, type, x: pos.x, y: pos.y, radius: r, isPocketed: false };
    }

    // Random number of black coins (4-8)
    const blackCount = 4 + Math.floor(Math.random() * 5);
    const whiteCount = 4 + Math.floor(Math.random() * 5);

    for (let i = 0; i < blackCount; i++) {
        appState.coins.push(placeRandom(`black_${i}`, 'black', PhysicsConstants.coinRadius));
    }
    for (let i = 0; i < whiteCount; i++) {
        appState.coins.push(placeRandom(`white_${i}`, 'white', PhysicsConstants.coinRadius));
    }

    // Queen (70% chance on board)
    if (Math.random() > 0.3) {
        appState.coins.push(placeRandom('queen', 'queen', PhysicsConstants.queenRadius));
        appState.matchState.queenStatus = 'onBoard';
    } else {
        appState.matchState.queenStatus = 'pocketed';
    }

    appState.matchState.remainingPlayer = appState.coins.filter(
        c => c.type === appState.playerColor && !c.isPocketed
    ).length;
    appState.matchState.remainingOpponent = appState.coins.filter(
        c => c.type === (appState.playerColor === 'black' ? 'white' : 'black') && !c.isPocketed
    ).length;

    renderer.drawBoard(appState.coins);
    updateBoardState();
}

// ============ Board State UI ============

function updateBoardState() {
    const blackCount = appState.coins.filter(c => c.type === 'black' && !c.isPocketed).length;
    const whiteCount = appState.coins.filter(c => c.type === 'white' && !c.isPocketed).length;
    const queenOnBoard = appState.coins.some(c => c.type === 'queen' && !c.isPocketed);

    document.getElementById('black-count').textContent = blackCount;
    document.getElementById('white-count').textContent = whiteCount;
    document.getElementById('queen-status').textContent = queenOnBoard ? 'On Board' : 'Pocketed';

    appState.matchState.remainingPlayer = appState.coins.filter(
        c => c.type === appState.playerColor && !c.isPocketed
    ).length;
    appState.matchState.remainingOpponent = appState.coins.filter(
        c => c.type === (appState.playerColor === 'black' ? 'white' : 'black') && !c.isPocketed
    ).length;
    appState.matchState.queenStatus = queenOnBoard ? 'onBoard' : 'pocketed';
}

// ============ AI Analysis ============

function analyzeBoard() {
    const btnAnalyze = document.getElementById('btn-analyze');
    const boardStatus = document.getElementById('board-status');

    btnAnalyze.disabled = true;
    boardStatus.classList.remove('hidden');

    // Use setTimeout to allow the UI to update before blocking
    setTimeout(() => {
        const result = strategyEngine.analyze(
            appState.coins,
            appState.playerColor,
            appState.matchState
        );

        boardStatus.classList.add('hidden');
        btnAnalyze.disabled = false;

        if (!result) {
            alert('No viable shots found. Try randomizing the board.');
            return;
        }

        appState.currentRecommendation = result;
        displayRecommendation(result);

        // Draw board with overlay
        const best = result.bestShot.candidate;
        renderer.drawBoard(appState.coins, {
            strikerPath: best.strikerPath,
            coinPath: best.coinPath,
            targetCoin: best.targetCoin,
            targetPocket: best.targetPocket,
            strikerPosition: { x: best.strikerX, y: best.strikerY },
        });

        document.getElementById('btn-play-shot').disabled = false;
    }, 50);
}

function displayRecommendation(result) {
    const card = document.getElementById('recommendation-card');
    card.classList.remove('hidden');

    const best = result.bestShot;
    const prob = best.scores.pocketProbability;

    // Stats
    const probEl = document.querySelector('#stat-probability .stat-value');
    const probPct = Math.round(prob * 100);
    probEl.textContent = `${probPct}%`;
    probEl.className = 'stat-value';
    if (prob >= 0.7) probEl.classList.add('prob-high');
    else if (prob >= 0.4) probEl.classList.add('prob-medium');
    else probEl.classList.add('prob-low');

    const powerVal = Math.min(10, Math.max(1, Math.round(best.candidate.power / 600)));
    document.querySelector('#stat-power .stat-value').textContent = powerVal;

    document.querySelector('#stat-type .stat-value').textContent = best.candidate.shotType;

    // Info grid
    document.getElementById('info-target').textContent =
        best.candidate.targetCoin.type.charAt(0).toUpperCase() + best.candidate.targetCoin.type.slice(1);
    document.getElementById('info-pocket').textContent = best.candidate.targetPocket.name;
    document.getElementById('info-pocketable').textContent = `${result.pocketable.length} coin(s)`;
    document.getElementById('info-angle').textContent =
        `${Math.round(best.candidate.aimAngle * 180 / Math.PI)}°`;

    // Reasoning
    document.getElementById('reasoning-text').textContent = result.reasoning;

    // Analysis time
    document.getElementById('analysis-time').textContent =
        `${(result.analysisTime / 1000).toFixed(2)}s`;

    // Performance card
    const perfCard = document.getElementById('perf-card');
    perfCard.classList.remove('hidden');
    document.getElementById('perf-candidates').textContent = result.totalCandidates;
    document.getElementById('perf-evaluated').textContent = result.evaluatedCandidates;
    document.getElementById('perf-steps').textContent = best.simResult.stepCount;
    document.getElementById('perf-time').textContent =
        `${(result.analysisTime / 1000).toFixed(2)}s`;
    document.getElementById('perf-pocketed').textContent = best.simResult.pocketedCoinCount;

    // Alternatives card
    const altCard = document.getElementById('alternatives-card');
    const altBody = document.getElementById('alternatives-list');
    if (result.alternatives && result.alternatives.length > 0) {
        altCard.classList.remove('hidden');
        altBody.innerHTML = result.alternatives.map((alt, i) => `
            <div class="alt-entry">
                <span class="alt-rank">#${i + 2}</span>
                <span class="alt-desc">${alt.shotType} → ${alt.target} → ${alt.pocket}</span>
                <span class="alt-prob ${alt.probability >= 70 ? 'prob-high' : alt.probability >= 40 ? 'prob-medium' : 'prob-low'}">${alt.probability}%</span>
            </div>
        `).join('');
    } else {
        altCard.classList.add('hidden');
    }
}

// ============ Shot Playback ============

function playShot() {
    if (!appState.currentRecommendation) return;

    const btnPlay = document.getElementById('btn-play-shot');
    const btnAnalyze = document.getElementById('btn-analyze');
    const btnRandom = document.getElementById('btn-randomize');
    btnPlay.disabled = true;
    btnAnalyze.disabled = true;
    btnRandom.disabled = true;

    const best = appState.currentRecommendation.bestShot;
    const simResult = best.simResult;

    // Animate the shot
    renderer.animateShot(appState.coins, simResult.trajectories, () => {
        // Animation complete — update state
        const targetPocketed = simResult.pocketed.some(
            p => p.bodyID === best.candidate.targetCoin.id
        );

        // Update coin positions from simulation
        for (const finalBody of simResult.finalBodies) {
            const coin = appState.coins.find(c => c.id === finalBody.id);
            if (coin) {
                coin.x = finalBody.x;
                coin.y = finalBody.y;
                coin.isPocketed = finalBody.isPocketed;
            }
        }

        // Record shot history
        const histEntry = {
            turn: appState.turn,
            target: best.candidate.targetCoin.type,
            pocket: best.candidate.targetPocket.name,
            shotType: best.candidate.shotType,
            success: targetPocketed,
            pocketed: simResult.pocketedCoinCount,
            foul: simResult.strikerPocketed,
        };
        appState.shotHistory.push(histEntry);
        updateShotHistory();

        // Advance turn
        appState.turn++;
        document.getElementById('turn-label').textContent = `Turn ${appState.turn}`;

        // Update board state
        updateBoardState();

        // Clear recommendation
        appState.currentRecommendation = null;
        document.getElementById('recommendation-card').classList.add('hidden');
        document.getElementById('perf-card').classList.add('hidden');
        document.getElementById('alternatives-card').classList.add('hidden');

        // Redraw board (final state)
        renderer.drawBoard(appState.coins);

        // Re-enable buttons
        btnAnalyze.disabled = false;
        btnRandom.disabled = false;
    });
}

function updateShotHistory() {
    const container = document.getElementById('shot-history');

    if (appState.shotHistory.length === 0) {
        container.innerHTML = '<div class="empty-history">No shots yet</div>';
        return;
    }

    container.innerHTML = appState.shotHistory.map(entry => `
        <div class="history-entry">
            <span class="history-turn">T${entry.turn}</span>
            <span class="history-desc">
                ${entry.shotType} → ${entry.target} → ${entry.pocket}
                ${entry.foul ? '<span class="foul-badge">Foul</span>' : ''}
            </span>
            <span class="history-result ${entry.success ? 'success' : 'miss'}">
                ${entry.success ? '✓' : '✗'}
            </span>
        </div>
    `).reverse().join('');
}

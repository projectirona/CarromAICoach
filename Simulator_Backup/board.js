// ============================================
// Carrom AI Coach — Board Renderer (Canvas)
// Renders the carrom board, coins, overlays, and shot animations
// ============================================

class BoardRenderer {
    constructor(canvasId) {
        this.canvas = document.getElementById(canvasId);
        this.ctx = this.canvas.getContext('2d');
        this.size = this.canvas.width;
        this.center = this.size / 2;

        // Scale: pixels per mm
        this.scale = (this.size - 60) / PhysicsConstants.playingAreaDimension;
        this.boardOffset = 30; // margin

        // Animation state
        this.animating = false;
        this.animFrames = [];
        this.animIndex = 0;
        this.animCallback = null;
    }

    // ============ Coordinate Conversion ============

    toCanvas(boardX, boardY) {
        return {
            x: this.center + boardX * this.scale,
            y: this.center + boardY * this.scale,
        };
    }

    toBoard(canvasX, canvasY) {
        return {
            x: (canvasX - this.center) / this.scale,
            y: (canvasY - this.center) / this.scale,
        };
    }

    mmToPixels(mm) {
        return mm * this.scale;
    }

    // ============ Full Board Draw ============

    drawBoard(coins, overlay = null) {
        const ctx = this.ctx;
        const s = this.size;

        // Clear
        ctx.clearRect(0, 0, s, s);

        // Outer frame — rich wood texture gradient
        const frameGrad = ctx.createLinearGradient(0, 0, s, s);
        frameGrad.addColorStop(0, '#5a3015');
        frameGrad.addColorStop(0.5, '#4a2810');
        frameGrad.addColorStop(1, '#3a1e0a');
        ctx.fillStyle = frameGrad;
        ctx.fillRect(0, 0, s, s);

        // Board surface
        const half = this.mmToPixels(PhysicsConstants.halfBoard);
        const surfaceX = this.center - half;
        const surfaceY = this.center - half;
        const surfaceW = half * 2;

        // Board surface gradient (subtle light from top-left)
        const surfGrad = ctx.createRadialGradient(
            surfaceX + surfaceW * 0.3, surfaceY + surfaceW * 0.3, surfaceW * 0.1,
            this.center, this.center, surfaceW * 0.8
        );
        surfGrad.addColorStop(0, '#e0b870');
        surfGrad.addColorStop(1, '#c89848');
        ctx.fillStyle = surfGrad;
        ctx.fillRect(surfaceX, surfaceY, surfaceW, surfaceW);

        // Border lines
        ctx.strokeStyle = '#3d2210';
        ctx.lineWidth = 2;
        ctx.strokeRect(surfaceX, surfaceY, surfaceW, surfaceW);

        // Inner border (playing area outline)
        const innerOffset = this.mmToPixels(15);
        ctx.strokeStyle = '#8b5e2e';
        ctx.lineWidth = 1.5;
        ctx.strokeRect(
            surfaceX + innerOffset, surfaceY + innerOffset,
            surfaceW - innerOffset * 2, surfaceW - innerOffset * 2
        );

        // Center circle
        const ccR = this.mmToPixels(PhysicsConstants.playingAreaDimension * 0.115);
        ctx.beginPath();
        ctx.arc(this.center, this.center, ccR, 0, Math.PI * 2);
        ctx.strokeStyle = '#3d2210';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Inner center circle
        ctx.beginPath();
        ctx.arc(this.center, this.center, ccR * 0.3, 0, Math.PI * 2);
        ctx.stroke();

        // Diagonal lines in center
        const diagLen = ccR * 0.7;
        ctx.lineWidth = 1;
        for (let a = Math.PI / 4; a < Math.PI * 2; a += Math.PI / 2) {
            const dx = Math.cos(a) * diagLen;
            const dy = Math.sin(a) * diagLen;
            ctx.beginPath();
            ctx.moveTo(this.center - dx, this.center - dy);
            ctx.lineTo(this.center + dx, this.center + dy);
            ctx.stroke();
        }

        // Baselines (top and bottom)
        this._drawBaseline(surfaceY + this.mmToPixels(PhysicsConstants.baselineOffset));
        this._drawBaseline(surfaceY + surfaceW - this.mmToPixels(PhysicsConstants.baselineOffset));

        // Pockets
        for (const p of PhysicsConstants.pocketCenters) {
            const cp = this.toCanvas(p.x, p.y);
            const pr = this.mmToPixels(PhysicsConstants.pocketCaptureRadius * 1.1);

            // Pocket shadow
            ctx.beginPath();
            ctx.arc(cp.x, cp.y, pr + 4, 0, Math.PI * 2);
            ctx.fillStyle = 'rgba(0,0,0,0.4)';
            ctx.fill();

            // Pocket hole
            ctx.beginPath();
            ctx.arc(cp.x, cp.y, pr, 0, Math.PI * 2);
            const pocketGrad = ctx.createRadialGradient(cp.x, cp.y, 0, cp.x, cp.y, pr);
            pocketGrad.addColorStop(0, '#0a0500');
            pocketGrad.addColorStop(1, '#1a0a00');
            ctx.fillStyle = pocketGrad;
            ctx.fill();

            // Pocket rim
            ctx.beginPath();
            ctx.arc(cp.x, cp.y, pr + 2, 0, Math.PI * 2);
            ctx.strokeStyle = '#2a1505';
            ctx.lineWidth = 3;
            ctx.stroke();
        }

        // Draw coins
        for (const coin of coins) {
            if (!coin.isPocketed) {
                this._drawCoin(coin);
            }
        }

        // Draw overlay
        if (overlay) {
            this._drawOverlay(overlay);
        }
    }

    // ============ Baseline ============

    _drawBaseline(canvasY) {
        const ctx = this.ctx;
        const half = this.mmToPixels(PhysicsConstants.halfBoard);
        const lineStart = this.center - half + this.mmToPixels(47);
        const lineEnd = this.center + half - this.mmToPixels(47);

        ctx.beginPath();
        ctx.moveTo(lineStart, canvasY);
        ctx.lineTo(lineEnd, canvasY);
        ctx.strokeStyle = '#3d2210';
        ctx.lineWidth = 1.5;
        ctx.stroke();

        // Baseline circles
        const circR = this.mmToPixels(25);
        ctx.beginPath();
        ctx.arc(lineStart, canvasY, circR, 0, Math.PI * 2);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(lineEnd, canvasY, circR, 0, Math.PI * 2);
        ctx.stroke();
    }

    // ============ Coin Drawing ============

    _drawCoin(coin) {
        const ctx = this.ctx;
        const cp = this.toCanvas(coin.x, coin.y);

        // Use visual radius for striker, regular radius for coins
        let r;
        if (coin.type === 'striker') {
            r = this.mmToPixels(PhysicsConstants.strikerVisualRadius);
        } else {
            r = this.mmToPixels(coin.radius || PhysicsConstants.coinRadius);
        }

        // Shadow
        ctx.beginPath();
        ctx.arc(cp.x + 1.5, cp.y + 2.5, r, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(0,0,0,0.3)';
        ctx.fill();

        // Coin body
        ctx.beginPath();
        ctx.arc(cp.x, cp.y, r, 0, Math.PI * 2);

        let fillColor, strokeColor, innerColor;
        switch (coin.type) {
            case 'black':
                fillColor = '#1a1a1a';
                strokeColor = 'rgba(255,255,255,0.2)';
                innerColor = '#333';
                break;
            case 'white':
                fillColor = '#f0f0f0';
                strokeColor = 'rgba(0,0,0,0.15)';
                innerColor = '#e8e8e8';
                break;
            case 'queen':
                fillColor = '#cc0000';
                strokeColor = 'rgba(255,100,100,0.4)';
                innerColor = '#ff3333';
                break;
            case 'striker':
                fillColor = '#555';
                strokeColor = 'rgba(255,255,255,0.3)';
                innerColor = '#888';
                break;
            default:
                fillColor = '#888';
                strokeColor = '#aaa';
                innerColor = '#999';
        }

        // Gradient fill
        const grad = ctx.createRadialGradient(
            cp.x - r * 0.3, cp.y - r * 0.3, r * 0.1,
            cp.x, cp.y, r
        );
        grad.addColorStop(0, innerColor);
        grad.addColorStop(1, fillColor);
        ctx.fillStyle = grad;
        ctx.fill();

        // Border
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 1.5;
        ctx.stroke();

        // Inner ring (decorative)
        ctx.beginPath();
        ctx.arc(cp.x, cp.y, r * 0.6, 0, Math.PI * 2);
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 0.5;
        ctx.stroke();
    }

    // ============ Shot Overlay ============

    _drawOverlay(overlay) {
        const ctx = this.ctx;

        // Striker path (green solid line with glow)
        if (overlay.strikerPath && overlay.strikerPath.length >= 2) {
            // Glow effect
            ctx.beginPath();
            const firstG = this.toCanvas(overlay.strikerPath[0].x, overlay.strikerPath[0].y);
            ctx.moveTo(firstG.x, firstG.y);
            for (let i = 1; i < overlay.strikerPath.length; i++) {
                const p = this.toCanvas(overlay.strikerPath[i].x, overlay.strikerPath[i].y);
                ctx.lineTo(p.x, p.y);
            }
            ctx.strokeStyle = 'rgba(50, 230, 80, 0.2)';
            ctx.lineWidth = 8;
            ctx.setLineDash([]);
            ctx.stroke();

            // Main line
            ctx.beginPath();
            const first = this.toCanvas(overlay.strikerPath[0].x, overlay.strikerPath[0].y);
            ctx.moveTo(first.x, first.y);
            for (let i = 1; i < overlay.strikerPath.length; i++) {
                const p = this.toCanvas(overlay.strikerPath[i].x, overlay.strikerPath[i].y);
                ctx.lineTo(p.x, p.y);
            }
            ctx.strokeStyle = 'rgba(50, 230, 80, 0.9)';
            ctx.lineWidth = 3;
            ctx.setLineDash([]);
            ctx.stroke();

            // Arrow head at end
            const last = overlay.strikerPath[overlay.strikerPath.length - 1];
            const prev = overlay.strikerPath[overlay.strikerPath.length - 2];
            this._drawArrowHead(prev, last, 'rgba(50, 230, 80, 0.9)');
        }

        // Coin path (yellow dashed)
        if (overlay.coinPath && overlay.coinPath.length >= 2) {
            ctx.beginPath();
            const first = this.toCanvas(overlay.coinPath[0].x, overlay.coinPath[0].y);
            ctx.moveTo(first.x, first.y);
            for (let i = 1; i < overlay.coinPath.length; i++) {
                const p = this.toCanvas(overlay.coinPath[i].x, overlay.coinPath[i].y);
                ctx.lineTo(p.x, p.y);
            }
            ctx.strokeStyle = 'rgba(255, 220, 30, 0.85)';
            ctx.lineWidth = 2.5;
            ctx.setLineDash([8, 4]);
            ctx.stroke();
            ctx.setLineDash([]);

            // Arrow head
            const last = overlay.coinPath[overlay.coinPath.length - 1];
            const prev = overlay.coinPath[overlay.coinPath.length - 2];
            this._drawArrowHead(prev, last, 'rgba(255, 220, 30, 0.85)');
        }

        // Target coin highlight (orange ring with pulse glow)
        if (overlay.targetCoin) {
            const cp = this.toCanvas(overlay.targetCoin.x, overlay.targetCoin.y);
            const r = this.mmToPixels(overlay.targetCoin.radius || PhysicsConstants.coinRadius) * 1.6;

            // Outer glow
            ctx.beginPath();
            ctx.arc(cp.x, cp.y, r + 6, 0, Math.PI * 2);
            ctx.strokeStyle = 'rgba(255, 100, 20, 0.2)';
            ctx.lineWidth = 8;
            ctx.stroke();

            // Main ring
            ctx.beginPath();
            ctx.arc(cp.x, cp.y, r, 0, Math.PI * 2);
            ctx.strokeStyle = 'rgba(255, 100, 20, 0.9)';
            ctx.lineWidth = 3;
            ctx.stroke();
        }

        // Target pocket highlight (blue glow)
        if (overlay.targetPocket) {
            const pp = this.toCanvas(overlay.targetPocket.x, overlay.targetPocket.y);
            const pr = this.mmToPixels(PhysicsConstants.pocketCaptureRadius * 1.3);

            // Outer glow
            ctx.beginPath();
            ctx.arc(pp.x, pp.y, pr + 6, 0, Math.PI * 2);
            ctx.fillStyle = 'rgba(30, 130, 255, 0.15)';
            ctx.fill();

            // Fill
            ctx.beginPath();
            ctx.arc(pp.x, pp.y, pr, 0, Math.PI * 2);
            ctx.fillStyle = 'rgba(30, 130, 255, 0.3)';
            ctx.fill();
            ctx.strokeStyle = 'rgba(30, 130, 255, 0.8)';
            ctx.lineWidth = 2;
            ctx.stroke();
        }

        // Striker placement — draw as a solid semitransparent striker
        if (overlay.strikerPosition) {
            const sp = this.toCanvas(overlay.strikerPosition.x, overlay.strikerPosition.y);
            const sr = this.mmToPixels(PhysicsConstants.strikerVisualRadius);

            // Semi-transparent striker body
            const grad = ctx.createRadialGradient(
                sp.x - sr * 0.25, sp.y - sr * 0.25, sr * 0.1,
                sp.x, sp.y, sr
            );
            grad.addColorStop(0, 'rgba(160, 160, 180, 0.5)');
            grad.addColorStop(1, 'rgba(80, 80, 100, 0.5)');
            ctx.beginPath();
            ctx.arc(sp.x, sp.y, sr, 0, Math.PI * 2);
            ctx.fillStyle = grad;
            ctx.fill();

            // Ring
            ctx.strokeStyle = 'rgba(200, 50, 230, 0.8)';
            ctx.lineWidth = 2;
            ctx.setLineDash([6, 3]);
            ctx.stroke();
            ctx.setLineDash([]);

            // Inner ring
            ctx.beginPath();
            ctx.arc(sp.x, sp.y, sr * 0.6, 0, Math.PI * 2);
            ctx.strokeStyle = 'rgba(200, 50, 230, 0.4)';
            ctx.lineWidth = 1;
            ctx.stroke();

            // Center dot
            ctx.beginPath();
            ctx.arc(sp.x, sp.y, 3, 0, Math.PI * 2);
            ctx.fillStyle = 'rgba(200, 50, 230, 1)';
            ctx.fill();
        }
    }

    _drawArrowHead(from, to, color) {
        const ctx = this.ctx;
        const fp = this.toCanvas(from.x, from.y);
        const tp = this.toCanvas(to.x, to.y);

        const angle = Math.atan2(tp.y - fp.y, tp.x - fp.x);
        const headLen = 12;

        ctx.beginPath();
        ctx.moveTo(tp.x, tp.y);
        ctx.lineTo(
            tp.x - headLen * Math.cos(angle - Math.PI / 6),
            tp.y - headLen * Math.sin(angle - Math.PI / 6)
        );
        ctx.lineTo(
            tp.x - headLen * Math.cos(angle + Math.PI / 6),
            tp.y - headLen * Math.sin(angle + Math.PI / 6)
        );
        ctx.closePath();
        ctx.fillStyle = color;
        ctx.fill();
    }

    // ============ Shot Animation ============

    animateShot(coins, trajectories, callback) {
        // Build animation frames from trajectories
        const ids = Object.keys(trajectories);
        const frameCount = Math.max(...ids.map(id => trajectories[id].length));

        this.animFrames = [];
        for (let f = 0; f < frameCount; f++) {
            const frame = [];
            for (const id of ids) {
                const traj = trajectories[id];
                const point = traj[Math.min(f, traj.length - 1)];
                const origCoin = coins.find(c => c.id === id);
                frame.push({
                    id,
                    x: point.x, y: point.y,
                    type: origCoin ? origCoin.type : (id === 'striker' ? 'striker' : 'black'),
                    radius: origCoin ? origCoin.radius : PhysicsConstants.coinRadius,
                    isPocketed: point.pocketed || false,
                });
            }
            this.animFrames.push(frame);
        }

        this.animIndex = 0;
        this.animating = true;
        this.animCallback = callback;
        this._animStep();
    }

    _animStep() {
        if (!this.animating || this.animIndex >= this.animFrames.length) {
            this.animating = false;
            if (this.animCallback) this.animCallback();
            return;
        }

        const frame = this.animFrames[this.animIndex];
        this.drawBoard(frame);
        this.animIndex++;

        requestAnimationFrame(() => this._animStep());
    }

    stopAnimation() {
        this.animating = false;
    }
}

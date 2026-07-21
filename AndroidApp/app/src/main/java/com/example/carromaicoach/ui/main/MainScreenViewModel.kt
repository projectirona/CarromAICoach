package com.example.carromaicoach.ui.main

import androidx.camera.core.ImageProxy
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.carromaicoach.data.models.Board
import com.example.carromaicoach.data.models.PlayerColor
import com.example.carromaicoach.data.models.Recommendation
import com.example.carromaicoach.engine.StrategyEngine
import com.example.carromaicoach.vision.CoinDetector
import com.example.carromaicoach.vision.PerspectiveCorrector
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class MainScreenUiState(
    val board: Board? = null,
    val recommendation: Recommendation? = null,
    val isAnalyzing: Boolean = false,
    val playerColor: PlayerColor = PlayerColor.WHITE,
    val scaleX: Float = 1f,
    val scaleY: Float = 1f
)

class MainScreenViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(MainScreenUiState())
    val uiState: StateFlow<MainScreenUiState> = _uiState.asStateFlow()

    val perspectiveCorrector = PerspectiveCorrector()
    private val coinDetector = CoinDetector()
    private val strategyEngine = StrategyEngine()
    
    private var scanRequested = false

    fun requestScan() {
        scanRequested = true
        _uiState.update { it.copy(isAnalyzing = true) }
    }

    fun onFrame(imageProxy: ImageProxy, viewWidth: Int, viewHeight: Int) {
        if (!scanRequested) {
            imageProxy.close()
            return
        }
        
        scanRequested = false
        
        // Calculate scale factor: Canvas (screen) size / OpenCV Image size.
        // If imageProxy is 640x480, and phone is portrait, the rotated image is 480x640.
        val isPortrait = imageProxy.imageInfo.rotationDegrees == 90 || imageProxy.imageInfo.rotationDegrees == 270
        val imageWidth = if (isPortrait) imageProxy.height else imageProxy.width
        val imageHeight = if (isPortrait) imageProxy.width else imageProxy.height
        
        val scaleX = if (imageWidth > 0) viewWidth.toFloat() / imageWidth else 1f
        val scaleY = if (imageHeight > 0) viewHeight.toFloat() / imageHeight else 1f
        
        viewModelScope.launch {
            try {
                // 1. OpenCV vision detection
                var board = coinDetector.detectFromImage(imageProxy)
                
                // Fallback to mock if OpenCV fails to find the board (e.g. testing in emulator)
                if (board == null) {
                    board = coinDetector.mockDetect()
                }
                
                // Update perspective corrector with board corners
                perspectiveCorrector.updateTransform(board.corners)
                
                // 2. Strategy Analysis
                val recommendation = strategyEngine.analyze(board, _uiState.value.playerColor)
                
                _uiState.update { 
                    it.copy(
                        board = board,
                        recommendation = recommendation,
                        isAnalyzing = false,
                        scaleX = scaleX,
                        scaleY = scaleY
                    ) 
                }
            } catch (e: Exception) {
                e.printStackTrace()
                _uiState.update { it.copy(isAnalyzing = false) }
            } finally {
                imageProxy.close()
            }
        }
    }

    fun togglePlayerColor() {
        _uiState.update { 
            val newColor = if (it.playerColor == PlayerColor.BLACK) PlayerColor.WHITE else PlayerColor.BLACK
            it.copy(playerColor = newColor)
        }
    }
}

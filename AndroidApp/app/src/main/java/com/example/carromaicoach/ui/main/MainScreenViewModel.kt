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

import android.app.Application
import androidx.lifecycle.AndroidViewModel

data class MainScreenUiState(
    val board: Board? = null,
    val recommendation: Recommendation? = null,
    val isAnalyzing: Boolean = false,
    val isPredictorMode: Boolean = false,
    val playerColor: PlayerColor = PlayerColor.WHITE,
    val scaleX: Float = 1f,
    val scaleY: Float = 1f,
    val errorMessage: String? = null
)

class MainScreenViewModel(application: Application) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(MainScreenUiState())
    val uiState: StateFlow<MainScreenUiState> = _uiState.asStateFlow()

    val perspectiveCorrector = PerspectiveCorrector()
    private val coinDetector = com.example.carromaicoach.vision.TFLiteCoinDetector(application)
    private val strategyEngine = StrategyEngine()
    
    private var scanRequested = false

    fun requestScan() {
        scanRequested = true
        _uiState.update { it.copy(isAnalyzing = true) }
    }
    
    fun togglePredictorMode() {
        _uiState.update { it.copy(isPredictorMode = !it.isPredictorMode) }
    }

    fun onFrame(imageProxy: ImageProxy, viewWidth: Int, viewHeight: Int) {
        val currentState = _uiState.value
        
        // Only process if scan was explicitly requested OR if we are in Predictor mode
        if (!scanRequested && !currentState.isPredictorMode) {
            imageProxy.close()
            return
        }
        
        // Throttle lock: If we are already analyzing a frame, drop this new frame
        if (currentState.isAnalyzing) {
            imageProxy.close()
            return
        }
        
        scanRequested = false
        _uiState.update { it.copy(isAnalyzing = true) }
        
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
                val board = coinDetector.detectFromImage(imageProxy)
                
                if (board == null) {
                    _uiState.update { 
                        it.copy(
                            isAnalyzing = false,
                            errorMessage = "Failed to detect the Carrom Board. Please ensure all 4 borders are visible and well-lit."
                        )
                    }
                    return@launch
                }
                
                // Update perspective corrector with board corners
                perspectiveCorrector.updateTransform(board.corners)
                
                // 2. Strategy Analysis
                val recommendation = strategyEngine.analyze(board, currentState.playerColor, currentState.isPredictorMode)
                
                _uiState.update { 
                    it.copy(
                        board = board,
                        recommendation = recommendation,
                        isAnalyzing = false,
                        scaleX = scaleX,
                        scaleY = scaleY,
                        errorMessage = null // Clear any previous errors
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

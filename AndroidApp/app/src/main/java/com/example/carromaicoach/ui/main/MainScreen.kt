package com.example.carromaicoach.ui.main

import androidx.compose.foundation.layout.*
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation3.runtime.NavKey
import com.example.carromaicoach.camera.CameraPreviewScreen
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import android.Manifest
import android.content.pm.PackageManager
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat

@Composable
fun MainScreen(
    onItemClick: (NavKey) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: MainScreenViewModel = viewModel(),
) {
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
        )
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { granted ->
            hasCameraPermission = granted
        }
    )

    LaunchedEffect(Unit) {
        if (!hasCameraPermission) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        if (hasCameraPermission) {
            // Base Layer: Camera Preview
            CameraPreviewScreen(onFrameAnalyzed = { imageProxy, viewWidth, viewHeight ->
                viewModel.onFrame(imageProxy, viewWidth, viewHeight)
            })
        } else {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text(text = "Camera permission is required", color = androidx.compose.ui.graphics.Color.White)
            }
        }

        
        // Top Layer: AR Overlay
        AROverlayCanvas(
            board = state.board,
            recommendation = state.recommendation,
            perspectiveCorrector = viewModel.perspectiveCorrector,
            scaleX = state.scaleX,
            scaleY = state.scaleY
        )
        
        // UI Controls Layer
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (state.errorMessage != null) {
                Text(
                    text = state.errorMessage!!,
                    color = androidx.compose.ui.graphics.Color.Red,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            } else if (state.isAnalyzing) {
                Text(text = "Analyzing Board...", color = androidx.compose.ui.graphics.Color.White)
            } else if (state.recommendation != null) {
                Text(
                    text = "Recommendation: ${state.recommendation!!.reasoning}",
                    color = androidx.compose.ui.graphics.Color.White
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Button(onClick = { viewModel.togglePlayerColor() }) {
                    Text("Playing as: ${state.playerColor.name}")
                }
                
                Button(onClick = { viewModel.requestScan() }) {
                    Text("Scan & Analyze")
                }
            }
        }
    }
}

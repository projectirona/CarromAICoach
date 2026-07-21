package com.example.carromaicoach.vision

import android.graphics.Matrix
import androidx.compose.ui.geometry.Offset

class PerspectiveCorrector(private val outputSize: Float = 800f) {
    
    // Homography matrix from camera image to top-down view
    private val transformMatrix = Matrix()
    
    // Inverse homography matrix from top-down back to camera image
    private val inverseMatrix = Matrix()

    fun updateTransform(corners: List<Offset>) {
        if (corners.size != 4) return
        
        val src = FloatArray(8)
        for (i in 0..3) {
            src[i * 2] = corners[i].x
            src[i * 2 + 1] = corners[i].y
        }
        
        val dst = floatArrayOf(
            0f, 0f,
            outputSize, 0f,
            outputSize, outputSize,
            0f, outputSize
        )
        
        transformMatrix.setPolyToPoly(src, 0, dst, 0, 4)
        transformMatrix.invert(inverseMatrix)
    }
    
    // Transform a point from camera coordinates to normalized board coordinates (0 to 1)
    fun transformToBoard(point: Offset): Offset {
        val pts = floatArrayOf(point.x, point.y)
        transformMatrix.mapPoints(pts)
        return Offset(pts[0] / outputSize, pts[1] / outputSize)
    }
    
    // Transform a point from normalized board coordinates (0 to 1) back to camera coordinates
    fun transformToCamera(point: Offset): Offset {
        val pts = floatArrayOf(point.x * outputSize, point.y * outputSize)
        inverseMatrix.mapPoints(pts)
        return Offset(pts[0], pts[1])
    }
    
    // Transform a point from millimeter board coordinates (-halfBoard to +halfBoard) back to camera coordinates
    fun mmToCamera(pointMM: Offset, halfBoard: Double): Offset {
        // Normalize
        val normX = (pointMM.x + halfBoard) / (halfBoard * 2)
        val normY = (pointMM.y + halfBoard) / (halfBoard * 2)
        return transformToCamera(Offset(normX.toFloat(), normY.toFloat()))
    }
}

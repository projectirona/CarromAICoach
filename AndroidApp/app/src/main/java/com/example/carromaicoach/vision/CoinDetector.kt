package com.example.carromaicoach.vision

import androidx.camera.core.ImageProxy
import androidx.compose.ui.geometry.Offset
import com.example.carromaicoach.data.models.Board
import com.example.carromaicoach.data.models.Coin
import com.example.carromaicoach.data.models.DetectionType
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.MatOfPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Scalar
import org.opencv.imgproc.Imgproc

class CoinDetector {

    // Main entry point for detecting from a CameraX ImageProxy
    fun detectFromImage(image: ImageProxy): Board? {
        val mat = imageProxyToMat(image)
        if (mat == null) return null
        
        // 1. Find Board Corners (Green Square)
        val corners = detectBoardCorners(mat)
        if (corners == null) {
            mat.release()
            return null
        }
        
        // 2. Find Coins using HoughCircles
        val coins = detectCoins(mat)
        
        mat.release()
        return Board(corners = corners, coins = coins)
    }

    private fun detectBoardCorners(mat: Mat): List<Offset>? {
        val hsv = Mat()
        Imgproc.cvtColor(mat, hsv, Imgproc.COLOR_RGBA2RGB)
        Imgproc.cvtColor(hsv, hsv, Imgproc.COLOR_RGB2HSV)
        
        // Threshold for green (carrom board rim or surface depending on board type)
        // Note: These values would need to be calibrated for a real board.
        val mask = Mat()
        Core.inRange(hsv, Scalar(35.0, 50.0, 50.0), Scalar(85.0, 255.0, 255.0), mask)
        
        val contours = ArrayList<MatOfPoint>()
        val hierarchy = Mat()
        Imgproc.findContours(mask, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)
        
        var largestContour: MatOfPoint? = null
        var maxArea = 0.0
        for (contour in contours) {
            val area = Imgproc.contourArea(contour)
            if (area > maxArea) {
                maxArea = area
                largestContour = contour
            }
        }
        
        mask.release()
        hsv.release()
        hierarchy.release()
        
        if (largestContour == null || maxArea < 50000.0) return null
        
        // Approximate to a 4-point polygon
        val curve = MatOfPoint2f(*largestContour.toArray())
        val approx = MatOfPoint2f()
        val epsilon = 0.05 * Imgproc.arcLength(curve, true)
        Imgproc.approxPolyDP(curve, approx, epsilon, true)
        
        if (approx.toArray().size != 4) return null
        
        // Sort corners (top-left, top-right, bottom-right, bottom-left)
        val points = approx.toArray().sortedBy { it.y }
        val top = points.take(2).sortedBy { it.x }
        val bottom = points.drop(2).sortedBy { it.x }
        
        return listOf(
            Offset(top[0].x.toFloat(), top[0].y.toFloat()),
            Offset(top[1].x.toFloat(), top[1].y.toFloat()),
            Offset(bottom[1].x.toFloat(), bottom[1].y.toFloat()),
            Offset(bottom[0].x.toFloat(), bottom[0].y.toFloat())
        )
    }

    private fun detectCoins(mat: Mat): List<Coin> {
        val gray = Mat()
        Imgproc.cvtColor(mat, gray, Imgproc.COLOR_RGBA2GRAY)
        Imgproc.GaussianBlur(gray, gray, org.opencv.core.Size(9.0, 9.0), 2.0)
        
        val circles = Mat()
        // Parameters: dp=1, minDist=20, param1=50, param2=30, minRadius=10, maxRadius=40
        Imgproc.HoughCircles(
            gray, circles, Imgproc.HOUGH_GRADIENT,
            1.0, 20.0, 50.0, 30.0, 10, 40
        )
        
        val detectedCoins = mutableListOf<Coin>()
        
        if (circles.cols() > 0) {
            for (i in 0 until circles.cols()) {
                val circle = circles.get(0, i)
                val x = circle[0].toFloat()
                val y = circle[1].toFloat()
                val radius = circle[2].toFloat()
                
                // Create a mask for the circle to get the average color
                val mask = Mat.zeros(mat.size(), CvType.CV_8UC1)
                Imgproc.circle(mask, Point(x.toDouble(), y.toDouble()), radius.toInt(), Scalar(255.0), -1)
                val meanColor = Core.mean(mat, mask)
                mask.release()
                
                val type = classifyCoinColor(meanColor.`val`)
                
                val coin = when(type) {
                    DetectionType.BLACK_COIN -> Coin.black(i, Offset(x, y))
                    DetectionType.WHITE_COIN -> Coin.white(i, Offset(x, y))
                    DetectionType.QUEEN -> Coin.queen(Offset(x, y))
                    DetectionType.STRIKER -> Coin.striker(Offset(x, y))
                }
                detectedCoins.add(coin)
            }
        }
        
        gray.release()
        circles.release()
        return detectedCoins
    }
    
    private fun classifyCoinColor(pixel: DoubleArray?): DetectionType {
        if (pixel == null || pixel.size < 3) return DetectionType.BLACK_COIN
        val r = pixel[0]
        val g = pixel[1]
        val b = pixel[2]
        
        // Wood coins with black/red rings. 
        // We use average color over the whole coin, so black rings lower the overall brightness.
        
        // Queen: High Red, lower Green/Blue
        if (r > 130 && r > g + 30 && r > b + 30) return DetectionType.QUEEN
        
        // Average brightness (R+G+B)
        val brightness = r + g + b
        
        // White coins are generally lighter (less black paint)
        if (brightness > 450) return DetectionType.WHITE_COIN
        
        // Black coins are generally darker (due to black painted rings/rims)
        if (brightness < 400) return DetectionType.BLACK_COIN
        
        // Fallback
        return DetectionType.STRIKER
    }

    private fun imageProxyToMat(image: ImageProxy): Mat? {
        val yBuffer = image.planes[0].buffer
        val uBuffer = image.planes[1].buffer
        val vBuffer = image.planes[2].buffer
        
        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()
        
        val nv21 = ByteArray(ySize + uSize + vSize)
        
        yBuffer.get(nv21, 0, ySize)
        vBuffer.get(nv21, ySize, vSize)
        uBuffer.get(nv21, ySize + vSize, uSize)
        
        val yuv = Mat(image.height + image.height / 2, image.width, CvType.CV_8UC1)
        yuv.put(0, 0, nv21)
        
        val rgba = Mat()
        Imgproc.cvtColor(yuv, rgba, Imgproc.COLOR_YUV2RGBA_NV21, 4)
        
        yuv.release()
        
        // Rotate the Mat based on the sensor rotation
        val rotated = Mat()
        when (image.imageInfo.rotationDegrees) {
            90 -> Core.rotate(rgba, rotated, Core.ROTATE_90_CLOCKWISE)
            180 -> Core.rotate(rgba, rotated, Core.ROTATE_180)
            270 -> Core.rotate(rgba, rotated, Core.ROTATE_90_COUNTERCLOCKWISE)
            else -> rgba.copyTo(rotated)
        }
        
        rgba.release()
        return rotated
    }
    
    // Fallback for emulator testing since OpenCV requires physical camera feed
    fun mockDetect(): Board {
        return Board(
            corners = listOf(
                Offset(100f, 100f),
                Offset(900f, 100f),
                Offset(900f, 900f),
                Offset(100f, 900f)
            ),
            coins = listOf(
                Coin.queen(Offset(0f, 0f)),
                Coin.black(0, Offset(-100f, -50f)),
                Coin.white(0, Offset(100f, 50f)),
                Coin.black(1, Offset(-200f, 200f))
            )
        )
    }
}

package com.example.fiscai

import android.content.Context
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.concurrent.CopyOnWriteArrayList

/**
 * 截图管理器
 */
object ScreenshotManager {
    
    private val listeners = CopyOnWriteArrayList<ScreenshotListener>()
    private var contentObserver: ContentObserver? = null
    private var context: Context? = null
    private var lastScreenshotTime = 0L
    private var isListening = false
    
    /**
     * 注册截图监听器
     */
    fun registerListener(listener: ScreenshotListener) {
        listeners.add(listener)
    }
    
    /**
     * 移除截图监听器
     */
    fun unregisterListener(listener: ScreenshotListener) {
        listeners.remove(listener)
    }
    
    /**
     * 开始监听截图事件
     */
    fun startListening(context: Context) {
        // 如果已经在监听，先停止再重新开始
        if (isListening) {
            stopListening()
        }
        
        this.context = context
        
        if (contentObserver == null) {
            contentObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                override fun onChange(selfChange: Boolean, uri: Uri?) {
                    super.onChange(selfChange, uri)
                    handleMediaContentChange(uri)
                }
            }
        }
        
        try {
            // 监听外部存储的图片变化
            context.contentResolver.registerContentObserver(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                true,
                contentObserver!!
            )
            isListening = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    /**
     * 停止监听截图事件
     */
    fun stopListening() {
        try {
            contentObserver?.let { observer ->
                context?.contentResolver?.unregisterContentObserver(observer)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        contentObserver = null
        isListening = false
        // 注意：不清除listeners，因为服务可能需要保持监听器
    }
    
    /**
     * 检查是否正在监听
     */
    fun isListening(): Boolean = isListening
    
    /**
     * 清除所有监听器（仅在服务停止时调用）
     */
    fun clearAllListeners() {
        listeners.clear()
    }
    
    /**
     * 处理媒体内容变化
     */
    private fun handleMediaContentChange(uri: Uri?) {
        if (uri == null || context == null) return
        
        Log.d("ScreenshotManager", "检测到媒体变化: $uri")
        
        try {
            val projection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                arrayOf(
                    MediaStore.Images.Media._ID,
                    MediaStore.Images.Media.DATE_TAKEN,
                    MediaStore.Images.Media.DISPLAY_NAME,
                    MediaStore.Images.Media.RELATIVE_PATH
                )
            } else {
                arrayOf(
                    MediaStore.Images.Media.DATA,
                    MediaStore.Images.Media.DATE_TAKEN,
                    MediaStore.Images.Media.DISPLAY_NAME
                )
            }
            
            val cursor: Cursor? = context!!.contentResolver.query(
                uri,
                projection,
                null,
                null,
                MediaStore.Images.Media.DATE_TAKEN + " DESC"
            )
            
            cursor?.use {
                if (it.moveToFirst()) {
                    val dateTakenIndex = it.getColumnIndex(MediaStore.Images.Media.DATE_TAKEN)
                    val displayNameIndex = it.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME)
                    
                    if (dateTakenIndex >= 0 && displayNameIndex >= 0) {
                        val dateTaken = it.getLong(dateTakenIndex)
                        val displayName = it.getString(displayNameIndex)
                        
                        Log.d("ScreenshotManager", "检查图片: $displayName, 时间: $dateTaken")
                        
                        // 判断是否为新的截图
                        if (isNewScreenshot(null, displayName, dateTaken)) {
                            lastScreenshotTime = dateTaken
                            
                            // 首先尝试复制截图到应用私有目录
                            val copiedPath = copyScreenshotToPrivateDir(uri, displayName)
                            if (copiedPath != null) {
                                Log.d("ScreenshotManager", "截图已复制到: $copiedPath")
                                notifyListeners(copiedPath)
                            } else {
                                Log.w("ScreenshotManager", "复制截图失败，使用URI方式: $uri")
                                // 如果复制失败，直接使用URI方式
                                notifyListeners(uri.toString())
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e("ScreenshotManager", "处理媒体变化失败", e)
        }
    }
    
    /**
     * 复制截图到应用私有目录
     */
    private fun copyScreenshotToPrivateDir(uri: Uri, fileName: String?): String? {
        if (context == null) return null
        
        try {
            val inputStream: InputStream? = context!!.contentResolver.openInputStream(uri)
            if (inputStream == null) {
                Log.e("ScreenshotManager", "无法打开输入流: $uri")
                return null
            }
            
            // 使用文件管理器获取截图目录
            val screenshotsDir = ScreenshotFileManager.getScreenshotsDir(context!!)
            
            // 生成文件名
            val timestamp = System.currentTimeMillis()
            val finalFileName = fileName ?: "screenshot_$timestamp.jpg"
            val outputFile = File(screenshotsDir, "copy_${timestamp}_$finalFileName")
            
            // 复制文件
            inputStream.use { input ->
                FileOutputStream(outputFile).use { output ->
                    input.copyTo(output)
                }
            }
            
            Log.d("ScreenshotManager", "截图复制成功: ${outputFile.absolutePath}")
            return outputFile.absolutePath
            
        } catch (e: Exception) {
            Log.e("ScreenshotManager", "复制截图失败", e)
            return null
        }
    }
    
    /**
     * 判断是否为新的截图
     */
    private fun isNewScreenshot(data: String?, displayName: String?, dateTaken: Long): Boolean {
        if (displayName == null) return false
        
        Log.d("ScreenshotManager", "检查是否为截图 - 名称: $displayName, 时间: $dateTaken, 上次时间: $lastScreenshotTime")
        
        // 检查时间是否在合理范围内（10秒内，给更多缓冲时间）
        val currentTime = System.currentTimeMillis()
        if (currentTime - dateTaken > 10000) {
            Log.d("ScreenshotManager", "时间超出范围: ${currentTime - dateTaken}ms")
            return false
        }
        
        // 检查是否比上次截图时间新
        if (dateTaken <= lastScreenshotTime) {
            Log.d("ScreenshotManager", "时间不是最新的")
            return false
        }
        
        // 检查文件名称是否包含截图特征
        val lowerDisplayName = displayName.lowercase()
        
        val isScreenshot = (lowerDisplayName.contains("screenshot") ||
                lowerDisplayName.contains("screen") ||
                lowerDisplayName.startsWith("screenshot") ||
                lowerDisplayName.contains("截图") ||
                lowerDisplayName.contains("屏幕截图"))
        
        // 如果有数据路径，也检查路径
        if (data != null) {
            val lowerData = data.lowercase()
            val pathMatches = (lowerData.contains("screenshot") || 
                    lowerData.contains("screen") ||
                    lowerData.contains("pictures/screenshots") ||
                    lowerData.contains("dcim/screenshots"))
            if (pathMatches) {
                Log.d("ScreenshotManager", "路径匹配截图特征")
                return true
            }
        }
        
        Log.d("ScreenshotManager", "名称匹配截图特征: $isScreenshot")
        return isScreenshot
    }
    
    /**
     * 通知所有监听器
     */
    private fun notifyListeners(imagePath: String) {
        for (listener in listeners) {
            try {
                listener.onScreenshot(imagePath)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}

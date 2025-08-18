package com.example.fiscai

import android.content.Context
import android.util.Log
import java.io.File

/**
 * 截图文件管理器
 * 管理应用私有目录中的截图文件
 */
object ScreenshotFileManager {
    
    private const val SCREENSHOTS_DIR = "screenshots"
    private const val MAX_FILES = 20 // 最多保留20个截图文件
    private const val MAX_AGE_HOURS = 24 // 文件最多保留24小时
    
    /**
     * 获取截图目录
     */
    fun getScreenshotsDir(context: Context): File {
        val dir = File(context.filesDir, SCREENSHOTS_DIR)
        if (!dir.exists()) {
            dir.mkdirs()
        }
        return dir
    }
    
    /**
     * 清理旧的截图文件
     */
    fun cleanupOldScreenshots(context: Context) {
        try {
            val screenshotsDir = getScreenshotsDir(context)
            val files = screenshotsDir.listFiles() ?: return
            
            val currentTime = System.currentTimeMillis()
            val maxAge = MAX_AGE_HOURS * 60 * 60 * 1000L // 转换为毫秒
            
            // 删除超过24小时的文件
            files.filter { file ->
                currentTime - file.lastModified() > maxAge
            }.forEach { file ->
                if (file.delete()) {
                    Log.d("ScreenshotFileManager", "删除过期文件: ${file.name}")
                }
            }
            
            // 如果文件数量仍然超过限制，删除最旧的文件
            val remainingFiles = screenshotsDir.listFiles() ?: return
            if (remainingFiles.size > MAX_FILES) {
                val sortedFiles = remainingFiles.sortedBy { it.lastModified() }
                val filesToDelete = sortedFiles.take(remainingFiles.size - MAX_FILES)
                
                filesToDelete.forEach { file ->
                    if (file.delete()) {
                        Log.d("ScreenshotFileManager", "删除超量文件: ${file.name}")
                    }
                }
            }
            
            Log.d("ScreenshotFileManager", "文件清理完成，当前文件数: ${screenshotsDir.listFiles()?.size ?: 0}")
            
        } catch (e: Exception) {
            Log.e("ScreenshotFileManager", "清理文件失败", e)
        }
    }
    
    /**
     * 获取文件大小信息
     */
    fun getStorageInfo(context: Context): Map<String, Any> {
        return try {
            val screenshotsDir = getScreenshotsDir(context)
            val files = screenshotsDir.listFiles() ?: emptyArray()
            
            val totalSize = files.sumOf { it.length() }
            val fileCount = files.size
            
            mapOf(
                "file_count" to fileCount,
                "total_size_bytes" to totalSize,
                "total_size_mb" to totalSize / (1024 * 1024),
                "directory_path" to screenshotsDir.absolutePath
            )
        } catch (e: Exception) {
            Log.e("ScreenshotFileManager", "获取存储信息失败", e)
            emptyMap()
        }
    }
}

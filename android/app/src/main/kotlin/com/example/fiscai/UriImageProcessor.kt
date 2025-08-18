package com.example.fiscai

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

/**
 * URI图片处理器
 * 处理MediaStore URI的图片，解决权限问题
 */
object UriImageProcessor {
    
    /**
     * 从URI创建临时图片文件
     * 这个方法会在用户点击通知时调用，此时系统会暂时授予权限
     */
    fun createTempImageFromUri(context: Context, uriString: String): String? {
        try {
            val uri = Uri.parse(uriString)
            Log.d("UriImageProcessor", "处理URI: $uriString")
            
            // 尝试打开输入流
            val inputStream = context.contentResolver.openInputStream(uri)
            if (inputStream == null) {
                Log.e("UriImageProcessor", "无法打开URI输入流")
                return null
            }
            
            // 读取位图
            val bitmap = BitmapFactory.decodeStream(inputStream)
            inputStream.close()
            
            if (bitmap == null) {
                Log.e("UriImageProcessor", "无法解码位图")
                return null
            }
            
            // 创建临时文件
            val tempDir = File(context.cacheDir, "temp_screenshots")
            if (!tempDir.exists()) {
                tempDir.mkdirs()
            }
            
            val timestamp = System.currentTimeMillis()
            val tempFile = File(tempDir, "temp_screenshot_$timestamp.jpg")
            
            // 保存位图到临时文件
            val outputStream = FileOutputStream(tempFile)
            bitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
            outputStream.close()
            bitmap.recycle()
            
            Log.d("UriImageProcessor", "临时文件创建成功: ${tempFile.absolutePath}")
            return tempFile.absolutePath
            
        } catch (e: Exception) {
            Log.e("UriImageProcessor", "处理URI失败", e)
            return null
        }
    }
    
    /**
     * 检查URI是否可访问
     */
    fun isUriAccessible(context: Context, uriString: String): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            val inputStream = context.contentResolver.openInputStream(uri)
            val accessible = inputStream != null
            inputStream?.close()
            Log.d("UriImageProcessor", "URI可访问性: $accessible")
            accessible
        } catch (e: Exception) {
            Log.d("UriImageProcessor", "URI不可访问: $e")
            false
        }
    }
    
    /**
     * 清理临时文件
     */
    fun cleanupTempFiles(context: Context) {
        try {
            val tempDir = File(context.cacheDir, "temp_screenshots")
            if (!tempDir.exists()) return
            
            val files = tempDir.listFiles() ?: return
            val currentTime = System.currentTimeMillis()
            val maxAge = 2 * 60 * 60 * 1000L // 2小时
            
            files.filter { file ->
                currentTime - file.lastModified() > maxAge
            }.forEach { file ->
                if (file.delete()) {
                    Log.d("UriImageProcessor", "删除临时文件: ${file.name}")
                }
            }
            
        } catch (e: Exception) {
            Log.e("UriImageProcessor", "清理临时文件失败", e)
        }
    }
}

package com.example.fiscai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.fiscai/android"
    private val PERMISSION_REQUEST_CODE = 1001
    
    // 广播接收器，用于接收来自服务的截图检测事件
    private val screenshotBroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.fiscai.SCREENSHOT_DETECTED") {
                val imagePath = intent.getStringExtra("imagePath") ?: ""
                
                // 通知Flutter层
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod(
                        "onScreenshotDetected", 
                        mapOf("imagePath" to imagePath)
                    )
                }
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 创建通知渠道
        NotificationHelper.createNotificationChannel(this)
        
        // 注册广播接收器
        val filter = IntentFilter("com.example.fiscai.SCREENSHOT_DETECTED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenshotBroadcastReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenshotBroadcastReceiver, filter)
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "registScreenshotListener" -> {
                    registerScreenshotListener(result)
                }
                "unregistScreenshotListener" -> {
                    ScreenshotManager.stopListening()
                    result.success(true)
                }
                "startBackgroundScreenshotService" -> {
                    startBackgroundScreenshotService(result)
                }
                "stopBackgroundScreenshotService" -> {
                    stopBackgroundScreenshotService(result)
                }
                "isBackgroundServiceRunning" -> {
                    result.success(ScreenshotForegroundService.isRunning())
                }
                "getScreenshotStorageInfo" -> {
                    val storageInfo = ScreenshotFileManager.getStorageInfo(this)
                    result.success(storageInfo)
                }
                "cleanupScreenshotFiles" -> {
                    ScreenshotFileManager.cleanupOldScreenshots(this)
                    result.success(true)
                }
                "processUriToImage" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        val imagePath = UriImageProcessor.createTempImageFromUri(this, uriString)
                        if (imagePath != null) {
                            result.success(imagePath)
                        } else {
                            result.error("PROCESSING_FAILED", "无法处理URI图片", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "URI参数为空", null)
                    }
                }
                "isUriAccessible" -> {
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        val accessible = UriImageProcessor.isUriAccessible(this, uriString)
                        result.success(accessible)
                    } else {
                        result.success(false)
                    }
                }
                "requestNotificationPermission" -> {
                    requestNotificationPermission()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // 处理从通知启动的情况
        handleNotificationIntent(intent)
    }
    
    /**
     * 注册截图监听器
     */
    private fun registerScreenshotListener(result: MethodChannel.Result) {
        // 检查权限
        if (!hasRequiredPermissions()) {
            requestPermissions()
            result.error("PERMISSION_DENIED", "需要相关权限", null)
            return
        }
        
        // 创建截图监听器
        val listener = object : ScreenshotListener {
            override fun onScreenshot(imagePath: String) {
                // 在主线程中显示通知
                runOnUiThread {
                    NotificationHelper.showScreenshotNotification(this@MainActivity, imagePath)
                    
                    // 通知Flutter层
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, CHANNEL).invokeMethod(
                            "onScreenshotDetected", 
                            mapOf("imagePath" to imagePath)
                        )
                    }
                }
            }
        }
        
        // 注册监听器并开始监听
        ScreenshotManager.registerListener(listener)
        ScreenshotManager.startListening(this)
        result.success(true)
    }
    
    /**
     * 检查是否有必要的权限
     */
    private fun hasRequiredPermissions(): Boolean {
        val permissions = mutableListOf<String>()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(android.Manifest.permission.READ_MEDIA_IMAGES)
            permissions.add(android.Manifest.permission.POST_NOTIFICATIONS)
        } else {
            permissions.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        
        return permissions.all { permission ->
            ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    /**
     * 请求权限
     */
    private fun requestPermissions() {
        val permissions = mutableListOf<String>()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(android.Manifest.permission.READ_MEDIA_IMAGES)
            permissions.add(android.Manifest.permission.POST_NOTIFICATIONS)
        } else {
            permissions.add(android.Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        
        ActivityCompat.requestPermissions(
            this,
            permissions.toTypedArray(),
            PERMISSION_REQUEST_CODE
        )
    }
    
    /**
     * 请求通知权限
     */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    android.Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                    PERMISSION_REQUEST_CODE
                )
            }
        }
    }
    
    /**
     * 处理权限请求结果
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod(
                    "onPermissionResult",
                    mapOf("granted" to allGranted)
                )
            }
        }
    }
    
    /**
     * 处理通知点击启动的意图
     */
    private fun handleNotificationIntent(intent: Intent?) {
        if (intent?.getBooleanExtra("screenshot_detected", false) == true) {
            val action = intent.getStringExtra("action")
            val screenshotPath = intent.getStringExtra("screenshot_path")
            
            // 取消通知
            NotificationHelper.cancelNotification(this)
            
            // 通知Flutter层处理相应操作
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL).invokeMethod(
                    "onNotificationAction",
                    mapOf(
                        "action" to (action ?: "open_app"),
                        "screenshot_path" to screenshotPath
                    )
                )
            }
        }
    }
    
    /**
     * 处理新的Intent（当应用已经在运行时）
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }
    
    /**
     * 启动后台截图监听服务
     */
    private fun startBackgroundScreenshotService(result: MethodChannel.Result) {
        // 检查权限
        if (!hasRequiredPermissions()) {
            requestPermissions()
            result.error("PERMISSION_DENIED", "需要相关权限", null)
            return
        }
        
        try {
            ScreenshotForegroundService.startService(this)
            result.success(true)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "启动服务失败: ${e.message}", null)
        }
    }
    
    /**
     * 停止后台截图监听服务
     */
    private fun stopBackgroundScreenshotService(result: MethodChannel.Result) {
        try {
            ScreenshotForegroundService.stopService(this)
            result.success(true)
        } catch (e: Exception) {
            result.error("SERVICE_ERROR", "停止服务失败: ${e.message}", null)
        }
    }
    
    /**
     * 应用销毁时停止监听并取消注册广播接收器
     */
    override fun onDestroy() {
        super.onDestroy()
        
        // 停止前台监听（如果有的话）
        ScreenshotManager.stopListening()
        
        // 取消注册广播接收器
        try {
            unregisterReceiver(screenshotBroadcastReceiver)
        } catch (e: Exception) {
            // 忽略异常，可能已经取消注册了
        }
    }
}

package com.example.fiscai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * 截图监听前台服务
 * 在后台持续监听截图事件
 */
class ScreenshotForegroundService : Service() {
    
    companion object {
        const val CHANNEL_ID = "screenshot_service"
        const val NOTIFICATION_ID = 2001
        
        private var isServiceRunning = false
        private var latestScreenshotPath: String? = null
        
        fun isRunning(): Boolean = isServiceRunning
        
        fun getLatestScreenshotPath(): String? = latestScreenshotPath
        
        fun startService(context: Context) {
            val intent = Intent(context, ScreenshotForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, ScreenshotForegroundService::class.java)
            context.stopService(intent)
        }
    }
    
    private var wakeLock: PowerManager.WakeLock? = null
    private var screenshotListener: ScreenshotListener? = null
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onCreate() {
        super.onCreate()
        
        // 创建唤醒锁以防止CPU休眠
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "FiscAI::ScreenshotService"
        )
        
        // 创建通知渠道
        createNotificationChannel()
        
        isServiceRunning = true
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 启动前台服务
        startForeground(NOTIFICATION_ID, createNotification())
        
        // 获取唤醒锁
        wakeLock?.acquire(10*60*1000L /*10 minutes*/)
        
        // 清理旧的截图文件
        ScreenshotFileManager.cleanupOldScreenshots(this)
        
        // 清理临时URI图片文件
        UriImageProcessor.cleanupTempFiles(this)
        
        // 设置截图监听器
        setupScreenshotListener()
        
        // 开始监听截图
        ScreenshotManager.startListening(this)
        
        // 返回START_STICKY以确保服务在被系统杀死后重启
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // 停止监听
        ScreenshotManager.stopListening()
        
        // 移除监听器
        screenshotListener?.let {
            ScreenshotManager.unregisterListener(it)
        }
        
        // 释放唤醒锁
        wakeLock?.release()
        
        isServiceRunning = false
    }
    
    /**
     * 创建通知渠道
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "截图监听服务",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "在后台监听截图事件"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * 创建前台服务通知
     */
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 创建停止服务的意图
        val stopIntent = Intent(this, ServiceActionReceiver::class.java).apply {
            action = "STOP_SCREENSHOT_SERVICE"
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("斐账正在监听截图")
            .setContentText("轻触停止监听")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "停止",
                stopPendingIntent
            )
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setShowWhen(false)
            .build()
    }
    
    /**
     * 设置截图监听器
     */
    private fun setupScreenshotListener() {
        screenshotListener = object : ScreenshotListener {
            override fun onScreenshot(imagePath: String) {
                // 保存最新的截图路径
                latestScreenshotPath = imagePath
                
                // 显示截图检测通知
                NotificationHelper.showScreenshotNotification(this@ScreenshotForegroundService, imagePath)
                
                // 如果MainActivity正在运行，通知它
                sendBroadcastToApp(imagePath)
            }
        }
        
        screenshotListener?.let {
            ScreenshotManager.registerListener(it)
        }
    }
    
    /**
     * 发送广播给应用
     */
    private fun sendBroadcastToApp(imagePath: String) {
        val intent = Intent("com.example.fiscai.SCREENSHOT_DETECTED").apply {
            putExtra("imagePath", imagePath)
            setPackage(packageName)
        }
        sendBroadcast(intent)
    }
}

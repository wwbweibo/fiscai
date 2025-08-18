package com.example.fiscai

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * 通知助手类
 */
object NotificationHelper {
    
    private const val CHANNEL_ID = "screenshot_detection"
    private const val CHANNEL_NAME = "截图检测"
    private const val CHANNEL_DESCRIPTION = "检测到截图时发送通知"
    private const val NOTIFICATION_ID = 1001
    
    /**
     * 创建通知渠道
     */
    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = CHANNEL_DESCRIPTION
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * 显示截图检测通知
     */
    fun showScreenshotNotification(context: Context, imagePath: String? = null) {
        createNotificationChannel(context)
        
        // 创建点击通知后打开应用的意图
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("screenshot_detected", true)
            imagePath?.let { putExtra("screenshot_path", it) }
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 创建"识别账单"操作按钮的意图
        val recognizeIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("action", "recognize_bill")
            putExtra("screenshot_detected", true)
            imagePath?.let { putExtra("screenshot_path", it) }
        }
        
        val recognizePendingIntent = PendingIntent.getActivity(
            context, 1, recognizeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 创建"忽略"操作按钮的意图
        val ignoreIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = "IGNORE_SCREENSHOT"
        }
        
        val ignorePendingIntent = PendingIntent.getBroadcast(
            context, 2, ignoreIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 构建通知
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("检测到截图")
            .setContentText("是否需要为您识别并记录账单？")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_menu_camera,
                "识别账单",
                recognizePendingIntent
            )
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "忽略",
                ignorePendingIntent
            )
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("检测到您刚刚截取了屏幕截图，是否需要为您识别并记录账单信息？")
            )
        
        // 发送通知
        try {
            with(NotificationManagerCompat.from(context)) {
                notify(NOTIFICATION_ID, builder.build())
            }
        } catch (e: SecurityException) {
            // 如果没有通知权限，可以在这里处理
            e.printStackTrace()
        }
    }
    
    /**
     * 取消通知
     */
    fun cancelNotification(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }
}

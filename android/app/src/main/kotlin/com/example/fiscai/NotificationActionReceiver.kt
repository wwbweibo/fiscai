package com.example.fiscai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * 通知操作广播接收器
 */
class NotificationActionReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        
        when (intent.action) {
            "IGNORE_SCREENSHOT" -> {
                // 忽略截图，取消通知
                NotificationHelper.cancelNotification(context)
            }
        }
    }
}

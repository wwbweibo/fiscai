package com.example.fiscai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * 服务操作广播接收器
 */
class ServiceActionReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        
        when (intent.action) {
            "STOP_SCREENSHOT_SERVICE" -> {
                // 停止截图监听服务
                ScreenshotForegroundService.stopService(context)
            }
        }
    }
}

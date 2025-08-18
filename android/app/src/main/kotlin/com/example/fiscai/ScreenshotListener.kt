package com.example.fiscai

/**
 * 截图监听器接口
 */
interface ScreenshotListener {
    /**
     * 截图事件回调
     * @param imagePath 截图文件路径
     */
    fun onScreenshot(imagePath: String)
}

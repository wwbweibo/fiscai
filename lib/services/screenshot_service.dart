import 'dart:developer';
import 'package:flutter/services.dart';

/// 截图监听服务
class ScreenshotService {
  static const MethodChannel _channel = MethodChannel('com.example.fiscai/android');
  
  static Function(String)? _onScreenshotDetected;
  static Function(String, String?)? _onNotificationAction;
  static Function(bool)? _onPermissionResult;
  
  /// 初始化截图服务
  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  /// 处理原生平台的方法调用
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onScreenshotDetected':
        final String imagePath = call.arguments['imagePath'] ?? '';
        _onScreenshotDetected?.call(imagePath);
        break;
      case 'onNotificationAction':
        final String action = call.arguments['action'] ?? '';
        final String? screenshotPath = call.arguments['screenshot_path'];
        _onNotificationAction?.call(action, screenshotPath);
        break;
      case 'onPermissionResult':
        final bool granted = call.arguments['granted'] ?? false;
        _onPermissionResult?.call(granted);
        break;
    }
  }
  
  /// 注册截图监听器
  static Future<bool> registerScreenshotListener() async {
    try {
      final result = await _channel.invokeMethod('registScreenshotListener');
      log('registerScreenshotListener result: $result');
      return result == true;
    } on PlatformException catch (e) {
      print('注册截图监听器失败: ${e.message}');
      return false;
    }
  }
  
  /// 取消截图监听器
  static Future<bool> unregisterScreenshotListener() async {
    try {
      final result = await _channel.invokeMethod('unregistScreenshotListener');
      return result == true;
    } catch (e) {
      print('取消截图监听器失败: $e');
      return false;
    }
  }
  
  /// 启动后台截图监听服务
  static Future<bool> startBackgroundService() async {
    try {
      final result = await _channel.invokeMethod('startBackgroundScreenshotService');
      return result == true;
    } on PlatformException catch (e) {
      print('启动后台服务失败: ${e.message}');
      return false;
    }
  }
  
  /// 停止后台截图监听服务
  static Future<bool> stopBackgroundService() async {
    try {
      final result = await _channel.invokeMethod('stopBackgroundScreenshotService');
      return result == true;
    } catch (e) {
      print('停止后台服务失败: $e');
      return false;
    }
  }
  
  /// 检查后台服务是否正在运行
  static Future<bool> isBackgroundServiceRunning() async {
    try {
      final result = await _channel.invokeMethod('isBackgroundServiceRunning');
      return result == true;
    } catch (e) {
      print('检查后台服务状态失败: $e');
      return false;
    }
  }
  
  /// 获取截图存储信息
  static Future<Map<String, dynamic>?> getScreenshotStorageInfo() async {
    try {
      final result = await _channel.invokeMethod('getScreenshotStorageInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('获取存储信息失败: $e');
      return null;
    }
  }
  
  /// 清理截图文件
  static Future<bool> cleanupScreenshotFiles() async {
    try {
      final result = await _channel.invokeMethod('cleanupScreenshotFiles');
      return result == true;
    } catch (e) {
      print('清理文件失败: $e');
      return false;
    }
  }
  
  /// 处理URI转换为图片文件
  static Future<String?> processUriToImage(String uri) async {
    try {
      final result = await _channel.invokeMethod('processUriToImage', {'uri': uri});
      return result as String?;
    } on PlatformException catch (e) {
      print('处理URI失败: ${e.message}');
      return null;
    }
  }
  
  /// 检查URI是否可访问
  static Future<bool> isUriAccessible(String uri) async {
    try {
      final result = await _channel.invokeMethod('isUriAccessible', {'uri': uri});
      return result == true;
    } catch (e) {
      print('检查URI可访问性失败: $e');
      return false;
    }
  }
  
  /// 请求通知权限
  static Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (e) {
      print('请求通知权限失败: $e');
    }
  }
  
  /// 设置截图检测回调
  static void setOnScreenshotDetected(Function(String imagePath) callback) {
    _onScreenshotDetected = callback;
  }
  
  /// 设置通知操作回调
  static void setOnNotificationAction(Function(String action, String? screenshotPath) callback) {
    _onNotificationAction = callback;
  }
  
  /// 设置权限结果回调
  static void setOnPermissionResult(Function(bool granted) callback) {
    _onPermissionResult = callback;
  }
  
  /// 清除所有回调
  static void clearCallbacks() {
    _onScreenshotDetected = null;
    _onNotificationAction = null;
    _onPermissionResult = null;
  }
}

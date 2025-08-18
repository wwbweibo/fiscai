import 'dart:io';
import 'package:flutter/material.dart';
import '../services/screenshot_service.dart';

/// 跨平台截图管理器
/// 处理iOS和Android平台的差异
class PlatformScreenshotManager {
  
  /// 启动截图监听（跨平台）
  static Future<bool> startScreenshotListening(BuildContext context) async {
    try {
      if (Platform.isIOS) {
        return await _startiOSScreenshotListening(context);
      } else if (Platform.isAndroid) {
        return await _startAndroidScreenshotListening(context);
      } else {
        _showUnsupportedPlatformMessage(context);
        return false;
      }
    } catch (e) {
      print('启动截图监听失败: $e');
      return false;
    }
  }
  
  /// 停止截图监听（跨平台）
  static Future<bool> stopScreenshotListening(BuildContext context) async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        final success = await ScreenshotService.stopBackgroundService();
        if (success) {
          _showStopMessage(context);
        }
        return success;
      }
      return false;
    } catch (e) {
      print('停止截图监听失败: $e');
      return false;
    }
  }
  
  /// 检查服务状态（跨平台）
  static Future<bool> isServiceRunning() async {
    try {
      return await ScreenshotService.isBackgroundServiceRunning();
    } catch (e) {
      print('检查服务状态失败: $e');
      return false;
    }
  }
  
  /// 获取平台特定的功能说明
  static String getPlatformFeatureDescription() {
    if (Platform.isIOS) {
      return '''
iOS截图监听功能：
• 自动检测截图事件
• 发送本地通知提醒
• 引导用户手动选择截图
• 支持前台和后台监听
• 遵循iOS隐私政策

注意：由于iOS系统限制，无法直接获取截图文件，需要用户手动选择。''';
    } else if (Platform.isAndroid) {
      return '''
Android截图监听功能：
• 自动检测截图事件
• 自动获取截图文件
• 直接进行AI识别处理
• 支持后台服务运行
• 智能文件管理

注意：支持直接获取和处理截图文件，提供完全自动化体验。''';
    } else {
      return '当前平台不支持截图监听功能。';
    }
  }
  
  /// 获取平台特定的使用说明
  static List<String> getPlatformUsageSteps() {
    if (Platform.isIOS) {
      return [
        '1. 启用截图监听服务',
        '2. 允许应用发送通知',
        '3. 正常使用设备截图（电源键+音量上键）',
        '4. 收到通知后点击"识别账单"',
        '5. 在相册中选择刚才的截图',
        '6. AI自动识别账单信息',
      ];
    } else if (Platform.isAndroid) {
      return [
        '1. 启用后台截图监听服务',
        '2. 允许必要的存储和通知权限',
        '3. 正常使用设备截图（电源键+音量下键）',
        '4. 收到通知后点击"识别账单"',
        '5. 应用自动处理截图文件',
        '6. AI自动识别账单信息',
      ];
    } else {
      return ['当前平台不支持截图监听功能'];
    }
  }
  
  // MARK: - Private Methods
  
  /// 启动iOS截图监听
  static Future<bool> _startiOSScreenshotListening(BuildContext context) async {
    final success = await ScreenshotService.startBackgroundService();
    
    if (success) {
      _showSnackBar(
        context,
        '✅ iOS截图监听已启动',
        '当您截图时会收到通知提醒',
        Colors.green,
      );
    } else {
      _showSnackBar(
        context,
        '❌ 启动失败',
        '请检查通知权限设置',
        Colors.red,
      );
    }
    
    return success;
  }
  
  /// 启动Android截图监听
  static Future<bool> _startAndroidScreenshotListening(BuildContext context) async {
    final success = await ScreenshotService.startBackgroundService();
    
    if (success) {
      _showSnackBar(
        context,
        '✅ Android后台服务已启动',
        '支持自动截图识别',
        Colors.green,
      );
    } else {
      _showSnackBar(
        context,
        '❌ 启动失败',
        '请检查存储和通知权限',
        Colors.red,
      );
    }
    
    return success;
  }
  
  /// 显示停止消息
  static void _showStopMessage(BuildContext context) {
    final platform = Platform.isIOS ? 'iOS' : 'Android';
    _showSnackBar(
      context,
      '🔄 $platform截图监听已停止',
      '可随时重新启动',
      Colors.orange,
    );
  }
  
  /// 显示不支持平台消息
  static void _showUnsupportedPlatformMessage(BuildContext context) {
    _showSnackBar(
      context,
      '❌ 平台不支持',
      '截图监听功能仅支持iOS和Android',
      Colors.red,
    );
  }
  
  /// 显示SnackBar消息
  static void _showSnackBar(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(16),
      ),
    );
  }
}

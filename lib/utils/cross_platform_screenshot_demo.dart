import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import '../services/screenshot_service.dart';
import 'platform_screenshot_manager.dart';

/// 跨平台截图功能演示页面
/// 支持iOS和Android不同的截图监听实现
class CrossPlatformScreenshotDemo extends StatefulWidget {
  const CrossPlatformScreenshotDemo({super.key});

  @override
  State<CrossPlatformScreenshotDemo> createState() => _CrossPlatformScreenshotDemoState();
}

class _CrossPlatformScreenshotDemoState extends State<CrossPlatformScreenshotDemo> {
  bool _isServiceRunning = false;
  String _lastAction = '无';
  Map<String, dynamic>? _storageInfo;
  
  @override
  void initState() {
    super.initState();
    _setupCallbacks();
    _refreshStatus();
  }

  /// 设置回调监听
  void _setupCallbacks() {
    ScreenshotService.setOnScreenshotDetected((String imagePath) {
      log('截图检测: $imagePath');
      if (mounted) {
        setState(() {
          _lastAction = Platform.isIOS ? 'iOS截图检测' : 'Android截图检测';
        });
      }
    });

    ScreenshotService.setOnNotificationAction((String action, String? screenshotPath) {
      log('通知操作: $action');
      if (mounted) {
        setState(() {
          _lastAction = '通知操作: $action';
        });
      }
    });
  }

  /// 刷新状态
  Future<void> _refreshStatus() async {
    try {
      final isRunning = await PlatformScreenshotManager.isServiceRunning();
      Map<String, dynamic>? storageInfo;
      
      // Android支持存储信息查询
      if (Platform.isAndroid) {
        storageInfo = await ScreenshotService.getScreenshotStorageInfo();
      }
      
      if (mounted) {
        setState(() {
          _isServiceRunning = isRunning;
          _storageInfo = storageInfo;
        });
      }
    } catch (e) {
      log('刷新状态失败: $e');
    }
  }

  /// 启动服务
  Future<void> _startService() async {
    final success = await PlatformScreenshotManager.startScreenshotListening(context);
    if (success) {
      _refreshStatus();
    }
  }

  /// 停止服务
  Future<void> _stopService() async {
    final success = await PlatformScreenshotManager.stopScreenshotListening(context);
    if (success) {
      _refreshStatus();
    }
  }

  /// 清理文件（仅Android）
  Future<void> _cleanupFiles() async {
    if (Platform.isAndroid) {
      final success = await ScreenshotService.cleanupScreenshotFiles();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Android文件清理完成'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformName = Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : '未知平台';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('$platformName 截图功能'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshStatus,
            icon: Icon(Icons.refresh),
            tooltip: '刷新状态',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            // 平台信息卡片
            _buildPlatformInfoCard(),
            
            SizedBox(height: 16),
            
            // 服务状态卡片
            _buildServiceStatusCard(),
            
            SizedBox(height: 16),
            
            // 存储信息卡片（仅Android）
            if (Platform.isAndroid) ...[
              _buildStorageInfoCard(),
              SizedBox(height: 16),
            ],
            
            // 最新事件卡片
            _buildLatestEventCard(),
            
            SizedBox(height: 16),
            
            // 功能说明卡片
            _buildFeatureDescriptionCard(),
            
            SizedBox(height: 16),
            
            // 使用步骤卡片
            _buildUsageStepsCard(),
          ],
        ),
      ),
    );
  }

  /// 平台信息卡片
  Widget _buildPlatformInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Platform.isIOS ? Icons.phone_iphone : Icons.android,
                  color: Platform.isIOS ? Colors.blue : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  '当前平台: ${Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : '未知'}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Flutter版本支持: ${Platform.isIOS || Platform.isAndroid ? '✅ 已支持' : '❌ 不支持'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// 服务状态卡片
  Widget _buildServiceStatusCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isServiceRunning ? Icons.check_circle : Icons.cancel,
                  color: _isServiceRunning ? Colors.green : Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  '截图监听: ${_isServiceRunning ? "运行中" : "已停止"}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isServiceRunning ? null : _startService,
                    icon: Icon(Icons.play_arrow),
                    label: Text('启动监听'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isServiceRunning ? _stopService : null,
                    icon: Icon(Icons.stop),
                    label: Text('停止监听'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 存储信息卡片（仅Android）
  Widget _buildStorageInfoCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Android存储信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (_storageInfo != null) ...[
              _buildInfoRow('文件数量', '${_storageInfo!['file_count'] ?? 0} 个'),
              _buildInfoRow('总大小', '${_storageInfo!['total_size_mb'] ?? 0} MB'),
              _buildInfoRow('存储路径', '${_storageInfo!['directory_path'] ?? '无'}'),
            ] else ...[
              Text('加载中...', style: TextStyle(color: Colors.grey)),
            ],
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _cleanupFiles,
                icon: Icon(Icons.cleaning_services),
                label: Text('清理文件'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 最新事件卡片
  Widget _buildLatestEventCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最新事件',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('最后操作: $_lastAction'),
          ],
        ),
      ),
    );
  }

  /// 功能说明卡片
  Widget _buildFeatureDescriptionCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text(
                  '功能说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              PlatformScreenshotManager.getPlatformFeatureDescription(),
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// 使用步骤卡片
  Widget _buildUsageStepsCard() {
    final steps = PlatformScreenshotManager.getPlatformUsageSteps();
    
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: Colors.green.shade700),
                SizedBox(width: 8),
                Text(
                  '使用步骤',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...steps.map((step) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text(step, style: TextStyle(height: 1.4)),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

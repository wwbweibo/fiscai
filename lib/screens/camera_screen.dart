// 相机页面

import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('拍照'),
      ),
      body: Center(
        child: Text('拍照功能开发中...'),
      ),
    );
  }
}
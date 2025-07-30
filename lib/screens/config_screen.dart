import 'package:flutter/material.dart';
import '../utils/app_config.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();

  final _supportedModels = [
    {
      'name': 'DeepSeek',
      'baseUrl': 'https://api.deepseek.com/v1',
      'model': 'deepseek-chat',
    },
    {
      'name': 'DeepSeek Reasoner',
      'baseUrl': 'https://api.deepseek.com/v1',
      'model': 'deepseek-reasoner',
    },
    {
      'name': 'Kimi',
      'baseUrl': 'https://api.moonshot.cn/v1',
      'model': 'kimi-latest',
    },
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = AppConfig.apiKey;
    _baseUrlController.text = AppConfig.baseUrl;
    _modelController.text = AppConfig.model;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    await AppConfig.saveConfig(
      _apiKeyController.text,
      _baseUrlController.text,
      _modelController.text,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配置'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 下拉选择
          Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 60, child: 
                const Text('模型:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                DropdownButton(
                value: AppConfig.model,
                items: [
                  for (var model in _supportedModels)
                    DropdownMenuItem(value: model['model'], child: Text(model['name'] ?? '')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _modelController.text = value!;
                      _baseUrlController.text = _supportedModels.firstWhere((model) => model['model'] == _modelController.text)['baseUrl']!;
                    });
                  },
                ),
              ],
            ),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _baseUrlController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _modelController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveConfig,
              child: const Text('保存配置'),
            ),
          ],
        ),
      ),
    );
  }
}
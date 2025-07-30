import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import '../providers/bill_provider.dart';
import '../widgets/image_source_bottom_sheet.dart';
import '../services/ocr_service.dart';

class ChatBillScreen extends StatefulWidget {
  const ChatBillScreen({super.key});

  @override
  State<ChatBillScreen> createState() => _ChatBillScreenState();
}

class _ChatBillScreenState extends State<ChatBillScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;
  String _currentAIResponse = '';
  bool _isReceiving = false;
  
  // 语音识别相关变量
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';
  
  // 操作按钮展开状态
  bool _isActionButtonsExpanded = false;

  @override
  void initState() {
    super.initState();
    // 初始化语音识别
    _initSpeech();
    
    // Initialize with a welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<BillProvider>();
      if (provider.chatHistory.isEmpty) {
        provider.chatHistory.add({
          'role': 'assistant',
          'content': '你好！我是你的财务助手FiscAI。你可以告诉我你的账单信息，比如"昨天在星巴克花了35元买咖啡"，我会帮你记录下来。你也可以问我查看账单或分析财务情况。'
        });
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  // 初始化语音识别
  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('语音识别错误: $error');
          setState(() {
            _isListening = false;
          });
          
          // 显示错误提示
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('语音识别出错: ${error.errorMsg}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        onStatus: (status) {
          print('语音识别状态: $status');
          // 只在真正完成时才更新状态
          if (status == 'done') {
            _onSpeechComplete();
          } else if (status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        debugLogging: true,
      );
      
      print('语音识别初始化: ${_speechEnabled ? "成功" : "失败"}');
      setState(() {});
    } catch (e) {
      print('语音识别初始化失败: $e');
      _speechEnabled = false;
      setState(() {});
    }
  }

  // 语音识别完成处理
  void _onSpeechComplete() {
    setState(() {
      _isListening = false;
      _isActionButtonsExpanded = false; // 语音识别完成后收起按钮组
    });
    
    // 如果有识别结果，自动填入输入框并发送
    if (_lastWords.isNotEmpty) {
      _textController.text = _lastWords;
      // 延迟一下再发送，让用户看到识别结果
      Future.delayed(Duration(milliseconds: 500), () {
        _sendMessage();
      });
    }
  }

  // 开始或停止语音识别
  Future<void> _toggleListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('语音识别不可用，请检查设备支持和权限'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  // 开始语音识别
  Future<void> _startListening() async {
    try {
      setState(() {
        _isListening = true;
        _lastWords = '';
      });

      await _speechToText.listen(
        onResult: (result) {
          print('语音识别结果: ${result.recognizedWords}, 是否最终: ${result.finalResult}');
          setState(() {
            _lastWords = result.recognizedWords;
          });
          
          // 如果是最终结果，自动完成
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _onSpeechComplete();
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'zh_CN',
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      print('开始语音识别失败: $e');
      setState(() {
        _isListening = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动语音识别失败'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // 停止语音识别
  Future<void> _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      
      // 如果有识别结果，处理结果
      if (_lastWords.isNotEmpty) {
        _textController.text = _lastWords;
        // 手动停止时立即发送
        await _sendMessage();
      }
    } catch (e) {
      print('停止语音识别失败: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty || _isSending) return;

    final message = _textController.text;
    _textController.clear();

    // Immediately add user message to history to prevent duplicates
    final provider = context.read<BillProvider>();
    provider.chatHistory.add({'role': 'user', 'content': message});
    await _sendMessageToLLM(provider.chatHistory);
  }

  Future<void> _sendMessageToLLM(List<Map<String, dynamic>> messages) async {
    setState(() {
      _isSending = true;
      _isReceiving = true;
      _currentAIResponse = '';
    });
    final provider = context.read<BillProvider>();
    final aiAssistant = provider.createAIAssistant();
    final stream = aiAssistant.sendMessageStream(messages);
    
    // Listen to the stream and update the UI
    await for (final content in stream) {
      if (!mounted) break;
      
      setState(() {
        _currentAIResponse += content;
      });
      
      // Auto scroll to bottom with better timing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    
    // Add final response to history
    if (_currentAIResponse.isNotEmpty && mounted) {
      provider.addAIResponseToHistory(_currentAIResponse);
    }
    
    if (mounted) {
      setState(() {
        _isSending = false;
        _isReceiving = false;
        _currentAIResponse = '';
      });
    }
  }

  void _showImageSourceBottomSheet() {
    ImageSourceBottomSheet.show(
      context,
      onCameraPressed: () async {
        try {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: ImageSource.camera);
          if (image != null) {
            _handleSelectedImage(image);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('拍照失败: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      onGalleryPressed: () async {
        try {
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            _handleSelectedImage(image);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('选择图片失败: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _handleSelectedImage(XFile imageFile) async {
    // 显示图片分析消息
    final provider = context.read<BillProvider>();
    final imageMessage = "我上传了一张账单图片，请帮我分析这张图片中的账单信息并记录到账单中。";
    
    // 添加用户消息
    provider.chatHistory.add({
      'role': 'user', 
      'content': imageMessage,
      'image_path': imageFile.path,
    });
    
    await _sendImageToAI(imageFile.path);
    // 立即刷新UI显示图片消息
    setState(() {});
  }

  Future<void> _sendImageToAI(String imagePath) async {
    final provider = context.read<BillProvider>();
    
    setState(() {
      _isSending = true;
      _isReceiving = true;
      _currentAIResponse = '';
    });

    try {
      setState(() {
        _isSending = true;
        _isReceiving = true;
        _currentAIResponse = '正在识别图片...';
      });

      // 先做OCR
      final ocrText = await OCRService.ocrImage(imagePath);
      // 如果ocrText为空或者识别失败，则告诉用户没有从图片中识别到账单信息
      if (ocrText.isEmpty || ocrText == 'OCRing image failed') {
        _isReceiving = false;
        _isSending = false;
        _currentAIResponse = '';
        provider.addAIResponseToHistory('我没有从图片中识别到账单信息，你可以尝试手动输入账单信息或者给我一张清晰的账单图片。');
        return;
      }
      
      // 做 deepcopy，不然ocr的message会污染provider的chatHistory
      final messages = provider.chatHistory.map((e) => Map<String, dynamic>.from(e)).toList();
              messages.add({
          'role': 'user',
          'content': '这里是图片识别结果：$ocrText，请帮我分析这张图片中的账单信息。',
        });
      await _sendMessageToLLM(messages);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('图片处理失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isReceiving = false;
          _currentAIResponse = '';
        });
      }
    }
  }

  // 检查是否可以重置（有多于一条消息或有用户消息）
  bool _canReset(BillProvider provider) {
    if (provider.chatHistory.isEmpty) return false;
    if (provider.chatHistory.length == 1) {
      // 只有一条消息，检查是否是欢迎消息
      final message = provider.chatHistory.first;
      return message['role'] != 'assistant' || 
             !message['content'].toString().contains('你好！我是你的财务助手FiscAI');
    }
    return true; // 有多条消息时可以重置
  }

  // 重置会话
  void _resetChat() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.refresh,
                color: Color(0xFF2563EB),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '重置会话',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            '确定要清空所有聊天记录吗？\n这个操作无法撤销。',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '取消',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                '确定重置',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 执行重置操作
  void _performReset() {
    final provider = context.read<BillProvider>();
    
    // 清空聊天记录
    provider.chatHistory.clear();
    
    // 添加新的欢迎消息
    provider.chatHistory.add({
      'role': 'assistant',
      'content': '你好！我是你的财务助手FiscAI。你可以告诉我你的账单信息，比如"昨天在星巴克花了35元买咖啡"，我会帮你记录下来。你也可以问我查看账单或分析财务情况。'
    });
    
    // 清空输入框
    _textController.clear();
    
    // 重置语音相关状态
    if (_isListening) {
      _speechToText.cancel();
    }
    setState(() {
      _isListening = false;
      _lastWords = '';
      _isSending = false;
      _isReceiving = false;
      _currentAIResponse = '';
      _isActionButtonsExpanded = false; // 重置时收起按钮组
    });
    
    // 显示成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('会话已重置'),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // 构建主操作按钮
  Widget _buildMainActionButton() {
    IconData icon;
    VoidCallback onTap;
    
    if (_isActionButtonsExpanded) {
      // 展开状态：显示关闭图标
      icon = Icons.close;
      onTap = () {
        setState(() {
          _isActionButtonsExpanded = false;
        });
      };
    } else if (_isListening) {
      // 正在录音：显示麦克风图标，点击停止录音
      icon = Icons.mic;
      onTap = () => _toggleListening();
    } else {
      // 默认状态：显示加号图标，点击展开菜单
      icon = Icons.add_circle_outline;
      onTap = () {
        setState(() {
          _isActionButtonsExpanded = true;
        });
      };
    }
    
    return _buildInputActionButton(
      icon: icon,
      onTap: onTap,
    );
  }

  // 构建可展开的操作按钮组
  Widget _buildExpandableActionButtons(BillProvider billProvider) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主操作按钮（智能显示当前最相关的功能）
          _buildMainActionButton(),
          
          // 展开的按钮组
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            width: _isActionButtonsExpanded ? 128 : 0, // 8 + 36 + 4 + 36 + 4 + 36 + 4 = 128
            child: ClipRect(
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 250),
                opacity: _isActionButtonsExpanded ? 1.0 : 0.0,
                child: _isActionButtonsExpanded
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        _buildInputActionButton(
                          icon: Icons.refresh_outlined,
                          onTap: _canReset(billProvider) ? () {
                            _resetChat();
                            // 执行操作后收起按钮组
                            setState(() {
                              _isActionButtonsExpanded = false;
                            });
                          } : () {},
                        ),
                        const SizedBox(width: 4),
                        _buildInputActionButton(
                          icon: Icons.camera_alt_outlined,
                          onTap: () {
                            _showImageSourceBottomSheet();
                            // 执行操作后收起按钮组
                            setState(() {
                              _isActionButtonsExpanded = false;
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildInputActionButton(
                          icon: _isListening ? Icons.mic : Icons.mic_outlined,
                          onTap: _speechEnabled ? () {
                            _toggleListening();
                            // 如果不是正在录音，执行操作后收起按钮组
                            if (!_isListening) {
                              setState(() {
                                _isActionButtonsExpanded = false;
                              });
                            }
                          } : () {},
                        ),
                        const SizedBox(width: 4),
                      ],
                    )
                  : Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (context, billProvider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8FAFC),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: Column(
            children: [
              // Chat history
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: billProvider.chatHistory.length + (_isReceiving ? 1 : 0),
                  itemBuilder: (context, index) {
                    // If we're receiving a response, the last item is the streaming response
                    if (_isReceiving && index == billProvider.chatHistory.length) {
                      return _buildAIResponseBubble(_currentAIResponse.isEmpty ? '正在输入...' : _currentAIResponse);
                    }
                    
                    final message = billProvider.chatHistory[index];
                    final isUser = message['role'] == 'user';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: isUser 
                        ? _buildUserMessageBubble(message)
                        : _buildAIResponseBubble(message['content']),
                    );
                  },
                ),
              ),
              
              // Input area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 0.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF64748B).withOpacity(0.04),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(28.0),
                    border: Border.all(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 左侧可展开功能按钮组
                      _buildExpandableActionButtons(billProvider),
                      
                      // 输入框
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 语音识别结果显示
                            if (_isListening && _lastWords.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                margin: EdgeInsets.only(bottom: 8.0),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Color(0xFFF59E0B),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.mic,
                                      color: Color(0xFFF59E0B),
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _lastWords,
                                        style: TextStyle(
                                          color: Color(0xFF92400E),
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            TextField(
                              controller: _textController,
                              minLines: 1,
                              maxLines: 4,
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 16,
                                height: 1.4,
                              ),
                              decoration: InputDecoration(
                                hintText: _isListening ? '正在录音...' : '输入消息...',
                                hintStyle: TextStyle(
                                  color: _isListening ? Color(0xFFEF4444) : Color(0xFF94A3B8),
                                  fontSize: 16,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                              ),
                              onTap: () {
                                // 点击输入框时收起按钮组
                                if (_isActionButtonsExpanded) {
                                  setState(() {
                                    _isActionButtonsExpanded = false;
                                  });
                                }
                              },
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ],
                        ),
                      ),
                      
                      // 发送按钮
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: _isSending 
                              ? null
                              : LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                            color: _isSending ? Color(0xFFE2E8F0) : null,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: _isSending ? null : [
                              BoxShadow(
                                color: Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(22),
                              onTap: _isSending ? null : _sendMessage,
                              child: Center(
                                child: _isSending 
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF64748B),
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build user message bubble
  Widget _buildUserMessageBubble(Map<String, dynamic> messageData) {
    final String message = messageData['content'] ?? '';
    final String? imagePath = messageData['image_path'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('消息已复制'),
                  backgroundColor: Color(0xFF2563EB),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(4.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 显示图片（如果有的话）
                  if (imagePath != null) ...[
                    Container(
                      width: 200,
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withOpacity(0.2),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                  
                  // 显示文字消息
                  if (message.isNotEmpty)
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build AI response bubble
  Widget _buildAIResponseBubble(String message) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          child: GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: message));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('消息已复制'),
                  backgroundColor: Color(0xFF2563EB),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Color(0xFFF8FAFC),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(4.0),
                ),
                border: Border.all(
                  color: Color(0xFF2563EB).withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: MarkdownBody(
                data: message + (_isReceiving && message == _currentAIResponse ? "▍" : ""),
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16.0,
                    height: 1.4,
                  ),
                  h1: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  h2: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  h3: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  code: TextStyle(
                    color: Color(0xFF2563EB),
                    backgroundColor: Color(0xFFF1F5F9),
                    fontSize: 14.0,
                    fontFamily: 'monospace',
                  ),
                  codeblockPadding: EdgeInsets.all(12.0),
                  codeblockDecoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  blockquote: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16.0,
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: TextStyle(
                    color: Color(0xFF2563EB),
                  ),
                  strong: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color: Color(0xFF1E293B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                selectable: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputActionButton({required IconData icon, required VoidCallback onTap}) {
    final bool isRecording = icon == Icons.mic;
    final bool isMicButton = icon == Icons.mic || icon == Icons.mic_outlined;
    final bool isResetButton = icon == Icons.refresh_outlined;
    
    // 获取provider来检查重置按钮状态
    final provider = context.read<BillProvider>();
    
    final bool isEnabled = isMicButton 
      ? _speechEnabled 
      : isResetButton 
        ? _canReset(provider)
        : true;
    
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording 
            ? Color(0xFFEF4444).withOpacity(0.1) 
            : isResetButton 
              ? Color(0xFF6366F1).withOpacity(0.1)
              : Colors.transparent,
          border: isRecording 
            ? Border.all(color: Color(0xFFEF4444), width: 2)
            : isResetButton
              ? Border.all(color: Color(0xFF6366F1).withOpacity(0.2), width: 1)
              : null,
        ),
        child: Icon(
          icon,
          color: isRecording 
            ? Color(0xFFEF4444) 
            : isResetButton
              ? Color(0xFF6366F1)
              : isEnabled 
                ? Color(0xFF64748B) 
                : Color(0xFFBDC3C7), // 禁用状态的灰色
          size: 22,
        ),
      ),
    );
  }
}
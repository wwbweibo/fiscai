import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/bill_provider.dart';
import '../models/bill.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize with a welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BillProvider>();
      if (provider.chatHistory.isEmpty) {
        provider.chatHistory.add({
          'role': 'assistant',
          'content': '你好！我是你的财务助手FiscAI。你可以告诉我你的账单信息，比如"昨天在星巴克花了35元买咖啡"，我会帮你记录下来。你也可以问我查看账单或分析财务情况。'
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty || _isSending) return;

    final message = _textController.text;
    _textController.clear();

    // Immediately add user message to history to prevent duplicates
    final provider = context.read<BillProvider>();
    // provider.chatHistory.add({'role': 'user', 'content': message});
    
    // Force a rebuild to show the user message immediately
    setState(() {
      _isSending = true;
      _isReceiving = true;
      _currentAIResponse = '';
    });

    // Send message to AI assistant
    final aiAssistant = provider.createAIAssistant();
    provider.chatHistory.add({'role': 'user', 'content': message});
    final stream = aiAssistant.sendMessageStream(message, provider.chatHistory);
    
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
                        ? _buildUserMessageBubble(message['content'])
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
                      // 左侧功能按钮组
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Row(
                          children: [
                                                         _buildInputActionButton(
                               icon: Icons.camera_alt_outlined,
                               onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('拍照功能开发中...'),
                                    backgroundColor: Color(0xFF2563EB),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                                                         _buildInputActionButton(
                               icon: Icons.mic_outlined,
                               onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('语音功能开发中...'),
                                    backgroundColor: Color(0xFF2563EB),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // 输入框
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          style: TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 16,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: '输入消息...',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
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
  Widget _buildUserMessageBubble(String message) {
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
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(
          icon,
          color: Color(0xFF64748B),
          size: 22,
        ),
      ),
    );
  }
}
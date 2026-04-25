import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mobile_ta/services/api_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _sendCount = 0;
  final int _maxSendCount = 3;
  bool _isGenerating = false;
  String? _apiKey;
  bool _isLoadingKey = true;
  String? _errorMessage;

  static final String openRouterUrl = dotenv.env['openRouterUrl'] ?? '';

  @override
  void initState() {
    super.initState();
    _fetchApiKey();
  }

  Future<void> _fetchApiKey() async {
    setState(() {
      _isLoadingKey = true;
      _errorMessage = null;
    });

    final response = await ApiService.getApiKey();

    if (response.success &&
        response.apiKey != null &&
        response.apiKey!.isNotEmpty) {
      setState(() {
        _apiKey = response.apiKey; // Gunakan apiKey bukan data
        _isLoadingKey = false;
      });
    } else {
      setState(() {
        _errorMessage =
            response.message ?? 'Failed to get API key: Empty response';
        _isLoadingKey = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty ||
        _sendCount >= _maxSendCount ||
        _isGenerating ||
        _apiKey == null)
      return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _sendCount++;
      _isGenerating = true;
    });

    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(openRouterUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "deepseek/deepseek-r1:free",
          "messages": [
            {"role": "user", "content": text},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['choices']?[0]?['message']?['content'] ?? 'No response';

        setState(() {
          _messages.add(ChatMessage(text: reply.trim(), isUser: false));
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  'Error ${response.statusCode}: ${response.reasonPhrase ?? response.body}',
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: 'Error: ${e.toString()}', isUser: false),
        );
      });
    } finally {
      setState(() => _isGenerating = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color:
              message.isUser
                  ? const Color(0xFF128d54).withOpacity(
                    0.15,
                  ) // User Bubble Hijau Muda
                  : Colors.white, // Bot Bubble Putih
          border:
              message.isUser
                  ? null
                  : Border.all(
                    color: const Color(0xFF128d54).withOpacity(0.3),
                  ), // Border hijau tipis utk Bot
          borderRadius: BorderRadius.circular(20),
        ),
        child: MarkdownBody(
          data: message.text,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(
              color:
                  message.isUser
                      ? const Color(0xFF128d54) // User Text hijau tegas
                      : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF128d54),
        title: const Text(
          'Chatbot',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            final shouldExit = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text("Yakin ingin keluar?"),
                    content: const Text("Chatbotmu akan hilang."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("Tidak"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Iya"),
                      ),
                    ],
                  ),
            );
            if (shouldExit == true) Navigator.pop(context);
          },
        ),
        actions: [
          if (_isLoadingKey)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (_errorMessage != null)
            IconButton(
              icon: const Icon(Icons.error, color: Colors.red),
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Sisa ${_maxSendCount - _sendCount}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      _sendCount >= _maxSendCount ? Colors.red : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoadingKey)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load API key',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _fetchApiKey,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText:
                          _sendCount >= _maxSendCount
                              ? 'Message limit reached'
                              : 'Type your message...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: const Color(0xFF128d54),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: const Color(0xFF128d54),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: const Color(0xFF128d54),
                          width: 3,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon:
                          _isGenerating
                              ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF128d54),
                                ),
                              )
                              : null,
                    ),
                    enabled:
                        _sendCount < _maxSendCount &&
                        !_isGenerating &&
                        _apiKey != null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isGenerating)
                  FloatingActionButton.small(
                    onPressed:
                        (_sendCount >= _maxSendCount ||
                                _isGenerating ||
                                _apiKey == null)
                            ? null
                            : _sendMessage,
                    child: const Icon(Icons.send),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

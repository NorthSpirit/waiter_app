import 'dart:async';
import 'package:flutter/material.dart';
import 'package:waiter_app/api/chat_api.dart';
import 'package:waiter_app/models/chat_message.dart';
import 'package:waiter_app/theme/design_tokens.dart';
import 'package:waiter_app/theme/theme_manager.dart';
import 'package:waiter_app/utils/text_validation.dart';
import 'package:waiter_app/widgets/components/action/touch_icon_widget.dart';
import 'package:waiter_app/widgets/components/display/standard_app_bar.dart';
import 'package:waiter_app/widgets/components/inputs/text_field_input.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    try {
      final messages = await ChatApi.list();
      setState(() {
        _messages.addAll(messages);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load messages.';
      });
    }
  }

  Future<void> _poll() async {
    if (_messages.isEmpty) return;
    try {
      final lastId = _messages.last.id;
      final newMessages = await ChatApi.pollAfter(lastId);
      if (newMessages.isNotEmpty && mounted) {
        final wasAtBottom = _isNearBottom();
        setState(() => _messages.addAll(newMessages));
        if (wasAtBottom) _scrollToBottom();
      }
    } catch (e) {
      // Silent — a missed poll cycle just gets caught by the next one.
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.pixels >= position.maxScrollExtent - 40;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (!isValidGenericField(text)) {
      setState(() => _validationError = "That doesn't look right — please rephrase.");
      return;
    }

    setState(() {
      _isSending = true;
      _validationError = null;
    });
    _messageController.clear();

    try {
      await ChatApi.send(text);
      await _poll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (context, _) {
        final theme = ThemeManager.instance.currentTheme;

        return Scaffold(
          appBar: StandardAppBar(
            leftActions: [
              TouchIconWidget(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
            ],
            title: 'Restaurant Chat',
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList(theme)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingSm,
                    vertical: DesignTokens.spacingXs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_validationError != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: DesignTokens.spacingXs, left: DesignTokens.spacingXs),
                          child: Text(
                            _validationError!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFieldInput(
                              controller: _messageController,
                              label: '',
                              hintText: 'Type a message...',
                              onChanged: (_) {
                                if (_validationError != null) {
                                  setState(() => _validationError = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingXs),
                          TouchIconWidget(
                            icon: _isSending ? Icons.hourglass_top : Icons.send,
                            onTap: _isSending ? () {} : _handleSend,
                          ),
                        ],
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

  Widget _buildMessageList(dynamic theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_messages.isEmpty) {
      return const Center(child: Text('No messages yet.'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(DesignTokens.spacingSm),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.spacingXs),
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: theme.content, fontSize: DesignTokens.fontBody),
              children: [
                TextSpan(
                  text: message.senderName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' (${message.sentAt}): ',
                  style: TextStyle(color: theme.content.withValues(alpha: DesignTokens.opacitySoft)),
                ),
                TextSpan(text: message.message),
              ],
            ),
          ),
        );
      },
    );
  }
}
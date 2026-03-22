import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:image_picker/image_picker.dart';

import 'package:prm393_finance_project/src/core/models/ai_assistant_response.dart';
import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/features/ai/ai_chat_persistence.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/features/budgets/providers/budget_providers.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  bool _chatLoaded = false;
  final _speech = SpeechToText();
  bool _listening = false;
  String? _conversationId;
  String? _pendingMessageForAccount;

  List<String> get _suggestions => [
        'suggestion_1'.tr(),
        'suggestion_2'.tr(),
        'suggestion_3'.tr(),
        'suggestion_4'.tr(),
        'suggestion_5'.tr(),
      ];

  @override
  void initState() {
    super.initState();
    _loadSavedChat();
  }

  Future<void> _loadSavedChat() async {
    try {
      final history = await ref.read(apiClientProvider).getAiHistory();
      if (history.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _messages.clear();
          for (final m in history) {
            final roleStr = m['role'] as String? ?? 'USER';
            final text = m['content'] as String? ?? '';
            final createdAt = m['createdAt'] != null ? DateTime.tryParse(m['createdAt'] as String) : null;
            _conversationId = m['conversationId'] as String?;
            if (roleStr == 'USER') {
              _messages.add(_ChatMessage.user(text, timestamp: createdAt));
            } else {
              _messages.add(_ChatMessage.assistant(text, timestamp: createdAt));
            }
          }
          _chatLoaded = true;
        });
        return;
      }
    } catch (e) {
      if (kDebugMode) print('Failed to load AI history from API: $e');
    }

    final (convId, list) = await loadAiChat();
    if (!mounted) return;
    setState(() {
      _conversationId = convId;
      _messages.clear();
      for (final m in list) {
        final r = m['r'] as int?;
        final t = m['t'] as String? ?? '';
        final ts = m['ts'] != null ? DateTime.tryParse(m['ts'] as String) : null;
        if (r == 0) {
          _messages.add(_ChatMessage.user(t, timestamp: ts));
        } else {
          _messages.add(_ChatMessage.assistant(t, timestamp: ts));
        }
      }
      _chatLoaded = true;
    });
  }

  Future<void> _persistChat() async {
    final list = _messages
        .map((m) => {
              'r': m.role == _ChatRole.user ? 0 : 1,
              't': m.text,
              'ts': m.timestamp.toIso8601String(),
            })
        .toList();
    await saveAiChat(_conversationId, list);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? preset, String? imagePath, String? base64Image}) async {
    if (_sending) return;
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty && base64Image == null) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage.user(
        text.isEmpty ? 'Gửi ảnh hóa đơn' : text,
        imagePath: imagePath,
        base64Image: base64Image,
      ));
      _messages.add(_ChatMessage.assistant('processing'.tr(), pending: true));
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final res = await ref.read(apiClientProvider).askAssistant(
        text,
        conversationId: _conversationId,
        language: context.locale.languageCode,
        base64Image: base64Image,
      );
      if (res.conversationId != null && res.conversationId!.isNotEmpty) {
        _conversationId = res.conversationId;
      }
      _replacePending(res);
      _persistChat();
      if (res.needsAccountSelection) {
        _pendingMessageForAccount = text;
        if (mounted) {
          setState(() => _sending = false);
        }
        await _promptAccountSelection();
        return;
      }
    } catch (e) {
      _replacePending(AiAssistantResponse(reply: 'Có lỗi khi gọi AI: $e', intent: 'UNKNOWN'));
      _persistChat();
    }

    if (mounted) {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);
    
    _sendMessage(preset: '', imagePath: image.path, base64Image: base64Image);
  }

  void _replacePending(AiAssistantResponse res) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.pending && m.role == _ChatRole.assistant);
      _messages.add(_ChatMessage.assistant(res.reply ?? ''));
    });
    if (res.refreshRequired || (res.intent.toUpperCase() == 'INSERT' && (res.createdCount ?? 0) > 0)) {
      refreshEntries(ref);
      refreshAccounts(ref);
      refreshBudgets(ref); // Refresh planning data
      ref.invalidate(entriesWithRefreshProvider);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _startListening() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('mic_permission_error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _inputController.text = result.recognizedWords;
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: context.locale.languageCode == 'vi' ? 'vi_VN' : 'en_US',
    );
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _promptAccountSelection() async {
    if (_pendingMessageForAccount == null || _pendingMessageForAccount!.isEmpty) return;
    List<AccountModel> accounts = [];
    try {
      accounts = await ref.read(accountsProvider.future);
    } catch (_) {}
    if (!mounted) return;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_wallet_hint'.tr())),
      );
      return;
    }

    final nf = NumberFormat('#,###', context.locale.toString());
    final selected = await showModalBottomSheet<AccountModel>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.separated(
        shrinkWrap: true,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
        itemBuilder: (context, index) {
          final account = accounts[index];
          return ListTile(
            leading: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
            title: Text(account.name, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              '${'balance_label'.tr()}: ${nf.format(account.balance)} đ',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => Navigator.of(ctx).pop(account),
          );
        },
      ),
    );

    if (selected == null) return;
    _sendMessageWithAccountSelection(selected);
  }

  Future<void> _sendMessageWithAccountSelection(AccountModel account) async {
    final message = _pendingMessageForAccount;
    if (message == null || message.isEmpty) return;
    _pendingMessageForAccount = null;
    if (_sending) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage.user('${'select_wallet_prefix'.tr()}: ${account.name}'));
      _messages.add(_ChatMessage.assistant('processing'.tr(), pending: true));
    });
    _scrollToBottom();

    try {
      final res = await ref.read(apiClientProvider).askAssistant(
            message,
            conversationId: _conversationId,
            accountId: account.id,
            language: context.locale.languageCode,
          );
      if (res.conversationId != null && res.conversationId!.isNotEmpty) {
        _conversationId = res.conversationId;
      }
      _replacePending(res);
      _persistChat();
    } catch (e) {
      _replacePending(AiAssistantResponse(reply: 'Có lỗi khi gọi AI: $e', intent: 'UNKNOWN'));
      _persistChat();
    }

    if (mounted) {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ai_assistant_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'new_chat_tooltip'.tr(),
            icon: const Icon(Icons.refresh),
            onPressed: _startNewConversation,
          ),
        ],
      ),
      body: !_chatLoaded
          ? const Center(child: CircularProgressIndicator())
          : SelectionArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: _messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildIntroCard(context);
                        }
                        final message = _messages[index - 1];
                        return _ChatBubble(message: message);
                      },
                    ),
                  ),
                  _buildInputBar(context),
                ],
              ),
            ),
    );
  }

  Widget _buildIntroCard(BuildContext context) {
    if (_messages.isNotEmpty) return const SizedBox(height: 8);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ai_intro_title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ai_intro_body'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions
                  .map((s) => ActionChip(
                        label: Text(s, overflow: TextOverflow.ellipsis),
                        onPressed: () => _sendMessage(preset: s),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'ai_input_hint'.tr(),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: _sending ? null : _pickImage,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _listening ? Icons.stop : Icons.mic,
                      color: _listening ? Colors.red : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _listening ? _stopListening : _startListening,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: (_sending || _listening) ? null : _sendMessage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: const CircleBorder(),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('start_new_chat_confirm'.tr()),
        content: Text('start_new_chat_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('clear'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await clearAiChat();
    setState(() {
      _conversationId = null;
      _messages.clear();
      _pendingMessageForAccount = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('new_chat_started'.tr())),
      );
    }
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  final _ChatRole role;
  final String text;
  final bool pending;
  final String? imagePath;
  final String? base64Image;
  final DateTime timestamp;

  _ChatMessage({
    required this.role,
    required this.text,
    this.pending = false,
    this.imagePath,
    this.base64Image,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory _ChatMessage.user(String text, {String? imagePath, String? base64Image, DateTime? timestamp}) =>
      _ChatMessage(role: _ChatRole.user, text: text, imagePath: imagePath, base64Image: base64Image, timestamp: timestamp);

  factory _ChatMessage.assistant(String text, {bool pending = false, DateTime? timestamp}) =>
      _ChatMessage(role: _ChatRole.assistant, text: text, pending: pending, timestamp: timestamp);
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == _ChatRole.user;
    final theme = Theme.of(context);
    
    final bubbleColor = isUser ? theme.colorScheme.primary : theme.cardColor;
    final textColor = isUser ? Colors.white : theme.textTheme.bodyLarge?.color;
    final borderColor = isUser ? Colors.transparent : theme.dividerColor;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bubbleColor,
          border: isUser ? null : Border.all(color: borderColor),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: message.base64Image != null
                                  ? Image.memory(base64Decode(message.base64Image!))
                                  : Image.file(io.File(message.imagePath!)),
                            ),
                            Positioned(
                              top: 40,
                              right: 20,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: message.base64Image != null
                        ? Image.memory(
                            base64Decode(message.base64Image!),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            io.File(message.imagePath!),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: (isUser ? Colors.white70 : theme.textTheme.bodySmall?.color)?.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

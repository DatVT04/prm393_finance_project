import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:prm393_finance_project/src/core/models/ai_assistant_response.dart';
import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/features/ai/ai_chat_persistence.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';

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
  String? _conversationId;
  String? _pendingMessageForAccount;

  final List<String> _suggestions = const [
    'Tháng này tôi tiêu nhiều nhất vào cái gì?',
    'Tháng trước tôi tiêu bao nhiêu?',
    'Danh sách chi tiêu của tôi hôm nay',
    'Hôm nay tôi ăn phở 45k',
    'Hôm nay tôi nạp 2 triệu vào ví',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedChat();
  }

  Future<void> _loadSavedChat() async {
    final (convId, list) = await loadAiChat();
    if (!mounted) return;
    setState(() {
      _conversationId = convId;
      _messages.clear();
      for (final m in list) {
        final r = m['r'] as int?;
        final t = m['t'] as String? ?? '';
        if (r == 0) {
          _messages.add(_ChatMessage.user(t));
        } else {
          _messages.add(_ChatMessage.assistant(t));
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

  Future<void> _sendMessage([String? preset]) async {
    if (_sending) return;
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage.user(text));
      _messages.add(_ChatMessage.assistant('Đang xử lý...', pending: true));
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final res = await ref.read(apiClientProvider).askAssistant(text, conversationId: _conversationId);
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

  void _replacePending(AiAssistantResponse res) {
    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.pending && m.role == _ChatRole.assistant);
      _messages.add(_ChatMessage.assistant(res.reply ?? ''));
    });
    if (res.refreshRequired || (res.intent.toUpperCase() == 'INSERT' && (res.createdCount ?? 0) > 0)) {
      refreshEntries(ref);
      refreshAccounts(ref);
      ref.invalidate(entriesWithRefreshProvider);
      ref.invalidate(entriesFilteredProvider);
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

  Future<void> _promptAccountSelection() async {
    if (_pendingMessageForAccount == null || _pendingMessageForAccount!.isEmpty) return;
    List<AccountModel> accounts = [];
    try {
      accounts = await ref.read(accountsProvider.future);
    } catch (_) {}
    if (!mounted) return;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có ví/tài khoản để chọn')),
      );
      return;
    }

    final nf = NumberFormat('#,###', 'vi_VN');
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
              'Số dư: ${nf.format(account.balance)} đ',
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
      _messages.add(_ChatMessage.user('Chọn ví: ${account.name}'));
      _messages.add(_ChatMessage.assistant('Đang xử lý...', pending: true));
    });
    _scrollToBottom();

    try {
      final res = await ref.read(apiClientProvider).askAssistant(
            message,
            conversationId: _conversationId,
            accountId: account.id,
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
        title: const Text('Trợ lý AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Bắt đầu cuộc trò chuyện mới',
            icon: const Icon(Icons.refresh),
            onPressed: _startNewConversation,
          ),
        ],
      ),
      body: !_chatLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
              'Hỏi đáp chi tiêu bằng AI',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn có thể hỏi thống kê hoặc nhập nhanh giao dịch bằng ngôn ngữ tự nhiên.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions
                  .map((s) => ActionChip(
                        label: Text(s, overflow: TextOverflow.ellipsis),
                        onPressed: () => _sendMessage(s),
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
                decoration: const InputDecoration(
                  hintText: 'Nhập câu hỏi hoặc ghi chú chi tiêu...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _sending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
        title: const Text('Bắt đầu cuộc trò chuyện mới?'),
        content: const Text('Lịch sử cuộc trò chuyện hiện tại sẽ bị xóa khỏi màn hình.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
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
        const SnackBar(content: Text('Đã bắt đầu cuộc trò chuyện mới')),
      );
    }
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  final _ChatRole role;
  final String text;
  final bool pending;

  _ChatMessage({required this.role, required this.text, this.pending = false});

  factory _ChatMessage.user(String text) => _ChatMessage(role: _ChatRole.user, text: text);

  factory _ChatMessage.assistant(String text, {bool pending = false}) =>
      _ChatMessage(role: _ChatRole.assistant, text: text, pending: pending);
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
        child: Text(
          message.text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

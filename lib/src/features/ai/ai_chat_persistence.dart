import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _keyConversationId = 'ai_chat_conversation_id';
const String _keyMessages = 'ai_chat_messages';

/**
 * Lưu trữ hội thoại AI xuống bộ nhớ máy (Local Storage) bằng SharedPreferences.
 * Lưu cả ID hội thoại và danh sách tin nhắn.
 */
Future<void> saveAiChat(String? conversationId, List<Map<String, dynamic>> messages) async {
  final prefs = await SharedPreferences.getInstance();
  if (conversationId != null && conversationId.isNotEmpty) {
    await prefs.setString(_keyConversationId, conversationId);
  } else {
    await prefs.remove(_keyConversationId);
  }
  await prefs.setString(_keyMessages, jsonEncode(messages));
}

/**
 * Tải hội thoại AI đã lưu từ bộ nhớ máy lên.
 */
Future<(String? conversationId, List<Map<String, dynamic>> messages)> loadAiChat() async {
  final prefs = await SharedPreferences.getInstance();
  final convId = prefs.getString(_keyConversationId);
  final raw = prefs.getString(_keyMessages);
  List<Map<String, dynamic>> messages = [];
  if (raw != null && raw.isNotEmpty) {
    try {
      final list = jsonDecode(raw) as List<dynamic>?;
      if (list != null) {
        for (final e in list) {
          if (e is Map<String, dynamic>) messages.add(e);
        }
      }
    } catch (_) {}
  }
  return (convId, messages);
}

/**
 * Xóa sạch hội thoại AI trong bộ nhớ máy.
 */
Future<void> clearAiChat() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyConversationId);
  await prefs.remove(_keyMessages);
}

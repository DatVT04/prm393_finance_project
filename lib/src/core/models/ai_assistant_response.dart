class AiAssistantResponse {
  final String reply;
  final String intent;
  final int? createdCount;
  final String? conversationId;
  final bool needsAccountSelection;

  AiAssistantResponse({
    required this.reply,
    required this.intent,
    this.createdCount,
    this.conversationId,
    this.needsAccountSelection = false,
  });

  factory AiAssistantResponse.fromJson(Map<String, dynamic> json) {
    return AiAssistantResponse(
      reply: json['reply'] as String? ?? '',
      intent: json['intent'] as String? ?? 'UNKNOWN',
      createdCount: json['createdCount'] as int?,
      conversationId: json['conversationId'] as String?,
      needsAccountSelection: json['needsAccountSelection'] as bool? ?? false,
    );
  }
}

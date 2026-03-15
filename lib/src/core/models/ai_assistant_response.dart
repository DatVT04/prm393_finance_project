class AiAssistantResponse {
  final String reply;
  final String intent;
  final int? createdCount;
  final String? conversationId;
  final bool needsAccountSelection;
  final bool refreshRequired;

  AiAssistantResponse({
    required this.reply,
    required this.intent,
    this.createdCount,
    this.conversationId,
    this.needsAccountSelection = false,
    this.refreshRequired = false,
  });

  factory AiAssistantResponse.fromJson(Map<String, dynamic> json) {
    return AiAssistantResponse(
      reply: json['reply'] as String? ?? '',
      intent: json['intent'] as String? ?? 'UNKNOWN',
      createdCount: json['createdCount'] as int?,
      conversationId: json['conversationId'] as String?,
      needsAccountSelection: json['needsAccountSelection'] as bool? ?? false,
      refreshRequired: json['refreshRequired'] as bool? ?? false,
    );
  }
}

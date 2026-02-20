/// Chat message model for AI chat functionality
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  /// Optional type field for categorizing AI messages (e.g., 'question', 'proposal', 'plan')
  /// Helps with compliance audits and message organization worldwide.
  /// Modular design allows for future subtypes and categorization extensions.
  final String? type;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type,
  });

  /// Create a copy with modified fields
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? type,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }
}

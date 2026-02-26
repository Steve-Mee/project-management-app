import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_model.freezed.dart';
part 'chat_message_model.g.dart';

/// Chat message model for AI chat functionality
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required bool isUser,
    required DateTime timestamp,

    /// Optional type field for categorizing AI messages (e.g., 'question', 'proposal', 'plan')
    /// Helps with compliance audits and message organization worldwide.
    /// Modular design allows for future subtypes and categorization extensions.
    String? type,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

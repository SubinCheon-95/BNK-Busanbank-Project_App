class ChatMessage {
  final String type;      // SYSTEM, CHAT, etc.
  final String? text;     // message
  final bool isMe;        // 사용자 여부

  ChatMessage({
    required this.type,
    required this.text,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      type: json['type'] ?? '',
      text: json['message'],
      isMe: json['senderType'] == 'USER',
    );
  }
}

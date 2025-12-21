class ChatbotMessage{
  final String text;
  final bool isUser;
  List<String>? actions;

  ChatbotMessage({
    required this.text,
    required this.isUser,
    this.actions,
});
}
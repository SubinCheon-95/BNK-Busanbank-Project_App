import 'dart:convert';

import 'package:tkbank/models/ui_message.dart';
import '../services/cs/chat/chat_api_service.dart';
import '../services/cs/chat/chat_websocket_service.dart';

class ChatController {
  final ChatApiService api;
  final ChatWebSocketService ws;
  final List<UiMessage> cachedMessages = [];

  int? sessionId;
  int userId;
  String senderType;

  ChatController({
    required this.api,
    required this.ws,
    this.userId = 0,
    this.senderType = "USER",
  });

  /// WebSocket 수신 스트림
  Stream<String> get stream => ws.stream;

  /// 🔹 상담 시작
  Future<bool> startChat(String inquiryType) async {
    if (sessionId == null) {
      final created = await api.startChatSession(
        userId: userId,
        inquiryType: inquiryType,
      );
      if (created == null) return false;
      sessionId = created;
    }

    if (!ws.isConnected) {
      ws.connect();

      ws.sendText(jsonEncode({
        "type": "ENTER",
        "sessionId": sessionId,
        "senderType": senderType,
        "senderId": userId,
      }));
    }

    sendChatMessage(inquiryType);
    return true;
  }

  /// 🔹 일반 채팅 메시지
  void sendChatMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (sessionId == null || !ws.isConnected) return;

    ws.sendText(jsonEncode({
      "type": "CHAT",
      "sessionId": sessionId,
      "senderType": senderType,
      "senderId": userId,
      "message": trimmed,
    }));
  }

  /// 🔹 상담 종료 요청 (END 전송만)
  void requestEndChat() {
    if (sessionId == null || !ws.isConnected) return;

    ws.sendText(jsonEncode({
      "type": "END",
      "sessionId": sessionId,
      "senderType": senderType,
      "senderId": userId,
    }));
  }

  /// 🔹 소켓만 종료 + 세션 초기화
  void disconnectAndReset() {
    ws.disconnect();
    sessionId = null;
  }

  /// 🔹 화면 dispose 시에만 호출
  void dispose() {
    ws.dispose();
  }

  void detach() {
    ws.disconnect();
    // sessionId 유지!
  }

}


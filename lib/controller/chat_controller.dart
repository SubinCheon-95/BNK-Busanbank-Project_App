import 'dart:convert';

import '../services/cs/chat/chat_api_service.dart';
import '../services/cs/chat/chat_websocket_service.dart';
import '../models/ui_message.dart';

class ChatController {
  final ChatApiService api;
  final ChatWebSocketService ws;

  int? sessionId;

  // 서버에서 USER 식별은 토큰/세션으로 처리하는 걸 추천
  // (userNo를 Flutter에서 굳이 만들 필요가 없게)
  int senderId = 0;
  String senderType = "USER";

  // ✅ 화면 재진입 복원용 캐시
  final List<UiMessage> cachedMessages = [];

  ChatController({
    required this.api,
    required this.ws,
    this.senderId = 0,
    this.senderType = "USER",
  });

  Stream<String> get stream => ws.stream;

  Future<bool> startChat(String inquiryType) async {
    // 1) 세션 없으면 생성(API)
    if (sessionId == null) {
      final created = await api.startChatSession(
        inquiryType: inquiryType,
      );
      if (created == null) return false;

      sessionId = created;
      print("✅ 세션 생성됨 sessionId=$sessionId");
    }

    // 2) WebSocket 연결 + ENTER
    if (!ws.isConnected) {
      ws.connect();
      ws.sendText(jsonEncode({
        "type": "ENTER",
        "sessionId": sessionId,
        "senderType": senderType,
        "senderId": senderId, // 지금은 0이어도 OK(서버에서 세션 userNo로 보정 권장)
      }));
    }

    // 3) 첫 메시지(문의유형) 전송
    sendChatMessage(inquiryType);
    return true;
  }

  void sendChatMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (sessionId == null) {
      print("❌ sessionId 없음. 먼저 startChat 필요");
      return;
    }
    if (!ws.isConnected) {
      print("❌ WebSocket 연결 안 됨");
      return;
    }

    ws.sendText(jsonEncode({
      "type": "CHAT",
      "sessionId": sessionId,
      "senderType": senderType,
      "senderId": senderId,
      "message": trimmed,
    }));
  }

  /// ✅ 상담 종료 요청(END 전송만)
  void requestEndChat() {
    if (sessionId == null || !ws.isConnected) return;

    ws.sendText(jsonEncode({
      "type": "END",
      "sessionId": sessionId,
      "senderType": senderType,
      "senderId": senderId,
    }));
  }

  /// ✅ 나가기(상담 유지): 세션은 유지하고 소켓만 끊기
  void detach() {
    ws.disconnect();
  }

  /// ✅ 종료: 세션/연결/캐시 정리(히스토리는 별도 API로)
  void disconnectAndReset() {
    ws.disconnect();
    sessionId = null;
    cachedMessages.clear();
  }

  void dispose() {
    ws.dispose();
  }
}


import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/cs/chat/chat_api_service.dart';
import '../services/cs/chat/chat_websocket_service.dart';
import '../models/ui_message.dart';

class ChatController {
  final ChatApiService api;
  final ChatWebSocketService ws;

  int? sessionId;

  int senderId = 0;
  String senderType = "USER";

  // ✅ 화면 재진입 복원용 캐시
  final List<UiMessage> cachedMessages = [];

  // ✅ 상담원 typing 상태
  final ValueNotifier<bool> agentTyping = ValueNotifier<bool>(false);

  StreamSubscription<String>? _sub;

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
      final created = await api.startChatSession(inquiryType: inquiryType);

      if (created == null) return false;

      sessionId = created;
      print("✅ 세션 생성됨 sessionId=$sessionId");
    }

    // 2) WebSocket 연결 + ENTER
    if (!ws.isConnected) {
      ws.connect();

      // ✅ 수신 리스너는 연결 직후 1번만 붙이기
      _attachIncomingListenerOnce();

      ws.sendText(jsonEncode({
        "type": "ENTER",
        "sessionId": sessionId,
        "senderType": senderType,
        "senderId": senderId,
      }));
    }

    // 3) 첫 메시지(문의유형) 전송
    sendChatMessage(inquiryType);
    return true;
  }

  void _attachIncomingListenerOnce() {
    if (_sub != null) return;

    _sub = ws.stream.listen((raw) {
      // 문자열 그대로 UI로 쓰는 곳이 이미 있다면:
      // 거기에서도 파싱하겠지만, typing은 여기서 확실히 처리해두는 게 안전합니다.

      Map<String, dynamic>? msg;
      try {
        msg = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        return; // JSON 아니면 무시(또는 로그)
      }

      final type = msg["type"]?.toString();
      final sender = msg["senderType"]?.toString();
      final msgSessionId = msg["sessionId"];

      // ✅ 현재 세션 아닌 것 무시 (TYPING도 포함해서 세션 필터 적용)
      if (sessionId != null && msgSessionId != null) {
        final s = (msgSessionId is int) ? msgSessionId : int.tryParse(msgSessionId.toString());
        if (s != null && s != sessionId) return;
      }

      // ✅ TYPING 처리
      if (type == "TYPING" && sender == "AGENT") {
        final isTyping = (msg["isTyping"] == true) || (msg["typing"] == true);
        agentTyping.value = isTyping;
        return;
      }

      // ✅ 상담원 CHAT 오면 typing 자동 OFF (웹이랑 동일)
      if (type == "CHAT" && sender == "AGENT") {
        agentTyping.value = false;
        return;
      }

      // ✅ END 오면 typing OFF
      if (type == "END") {
        agentTyping.value = false;
        return;
      }
    });
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

    // ✅ 화면도 즉시 OFF
    agentTyping.value = false;
  }

  /// ✅ 나가기(상담 유지): 세션은 유지하고 소켓만 끊기
  void detach() {
    ws.disconnect();
    agentTyping.value = false;
  }

  /// ✅ 종료: 세션/연결/캐시 정리(히스토리는 별도 API로)
  void disconnectAndReset({bool clearCache = false}) {
    ws.disconnect();
    sessionId = null;
    agentTyping.value = false;
    if (clearCache) cachedMessages.clear();
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    ws.dispose();
    agentTyping.dispose();
  }
}

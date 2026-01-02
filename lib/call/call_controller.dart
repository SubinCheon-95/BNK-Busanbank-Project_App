import 'dart:async';
import 'package:flutter/foundation.dart';
import 'voice_call_api.dart';

enum UiCallState {
  idle,
  requesting,   // enqueue 중
  waiting,      // 큐에 들어감(상담사 수락 대기)
  inCall,       // (고객 Agora join 등은 나중에 붙일 단계)
  ended,
  error,
}

class VoiceCallController extends ChangeNotifier {
  final VoiceCallApi api;

  VoiceCallController({required this.api});

  UiCallState state = UiCallState.idle;
  String sessionId = '';
  String errorMsg = '';

  Future<void> startCall({required String newSessionId}) async {
    try {
      sessionId = newSessionId;
      state = UiCallState.requesting;
      notifyListeners();

      // ✅ 핵심: voice 큐로 enqueue
      await api.enqueue(sessionId: sessionId);

      state = UiCallState.waiting;
      notifyListeners();
    } catch (e) {
      _toError(e);
    }
  }

  Future<void> endCall() async {
    try {
      if (sessionId.isEmpty) return;
      await api.end(sessionId: sessionId);

      state = UiCallState.ended;
      notifyListeners();
    } catch (e) {
      _toError(e);
    }
  }

  void _toError(Object e) {
    errorMsg = e.toString();
    state = UiCallState.error;
    notifyListeners();
  }
}

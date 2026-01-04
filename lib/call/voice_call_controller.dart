import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'voice_call_api.dart';
import 'voice_websocket_service.dart';

enum UiVoiceCallState { idle, requesting, waiting, accepted, ended, error }

class VoiceCallController extends ChangeNotifier {
  final VoiceCallApi api;
  final VoiceWebSocketService ws;

  VoiceCallController({
    required this.api,
    required this.ws,
  });

  UiVoiceCallState state = UiVoiceCallState.idle;
  String sessionId = '';
  String errorMsg = '';

  // accept 되었을 때 서버가 내려주는 값 저장
  String agoraChannel = '';
  String consultantId = '';

  StreamSubscription<String>? _wsSub;

  /// 화면 이동은 Controller가 직접 하지 말고, UI에서 콜백으로 처리
  VoidCallback? onAccepted;
  VoidCallback? onEnded;

  /// baseWs: ws://10.0.2.2:8080/busanbank
  void attachWs({required String baseWs}) {
    if (sessionId.isEmpty) return;

    ws.connect(baseWs: baseWs, voiceSessionId: sessionId);

    _wsSub ??= ws.stream.listen((raw) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final type = (m['type'] ?? '').toString();

        if (type == 'VOICE_ACCEPTED') {
          consultantId = (m['consultantId'] ?? '').toString();
          agoraChannel = (m['agoraChannel'] ?? '').toString();

          state = UiVoiceCallState.accepted;
          notifyListeners();

          onAccepted?.call();
        }

        if (type == 'VOICE_ENDED') {
          state = UiVoiceCallState.ended;
          notifyListeners();
          onEnded?.call();
        }
      } catch (_) {
        // 다른 메시지는 무시
      }
    }, onError: (e) {
      // WS 에러는 치명적 아니면 무시(원하면 state=error로 바꿔도 됨)
    });
  }

  Future<void> requestCall({required String newSessionId}) async {
    try {
      sessionId = newSessionId;
      state = UiVoiceCallState.requesting;
      errorMsg = '';
      notifyListeners();

      await api.enqueue(sessionId: sessionId);

      state = UiVoiceCallState.waiting;
      notifyListeners();
    } catch (e) {
      errorMsg = e.toString();
      state = UiVoiceCallState.error;
      notifyListeners();
    }
  }

  Future<void> endCall() async {
    try {
      if (sessionId.isEmpty) return;
      await api.end(sessionId: sessionId);

      state = UiVoiceCallState.ended;
      notifyListeners();

      onEnded?.call();
    } catch (e) {
      errorMsg = e.toString();
      state = UiVoiceCallState.error;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    ws.dispose();
    super.dispose();
  }
}

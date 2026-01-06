import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'voice_call_api.dart';
import 'voice_websocket_service.dart';

enum UiVoiceCallState { idle, requesting, waiting, accepted, ended, error }

class VoiceCallController extends ChangeNotifier {
  final VoiceCallApi api;
  final VoiceWebSocketService ws;

  VoiceCallController({required this.api, required this.ws});

  UiVoiceCallState state = UiVoiceCallState.idle;
  String sessionId = '';
  String errorMsg = '';

  String agoraChannel = '';
  String consultantId = '';

  StreamSubscription<String>? _wsSub;
  bool _ending = false;

  VoidCallback? onAccepted;
  VoidCallback? onEnded;

  void attachWs({required String baseWs}) {
    if (sessionId.isEmpty) return;

    ws.connect(baseWs: baseWs, voiceSessionId: sessionId);

    _wsSub ??= ws.stream.listen((raw) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final type = (m['type'] ?? '').toString();

        if (type == 'VOICE_ACCEPTED') {
          consultantId = (m['consultantId'] ?? '').toString();
          agoraChannel  = (m['agoraChannel'] ?? '').toString();

          state = UiVoiceCallState.accepted;
          notifyListeners();
          onAccepted?.call();
        }

        if (type == 'VOICE_ENDED') {
          // ✅ 서버가 END push한 경우: 상태만 종료로 만들고, end API는 다시 호출하지 않음
          state = UiVoiceCallState.ended;
          notifyListeners();
          onEnded?.call();
        }
      } catch (_) {}
    });
  }

  Future<void> requestCall({required String newSessionId}) async {
    try {
      sessionId = newSessionId;
      state = UiVoiceCallState.requesting;
      errorMsg = '';
      _ending = false;
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

  Future<void> endCall({String reason = ''}) async {
    if (_ending) return;
    _ending = true;

    try {
      if (sessionId.isEmpty) return;

      await api.end(sessionId: sessionId, reason: reason);

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

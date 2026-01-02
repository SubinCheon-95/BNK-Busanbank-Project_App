import 'package:flutter/foundation.dart';
import 'voice_call_api.dart';

enum UiVoiceCallState {
  idle,
  requesting,
  waiting,
  ended,
  error,
}

class VoiceCallController extends ChangeNotifier {
  final VoiceCallApi api;
  VoiceCallController({required this.api});

  UiVoiceCallState state = UiVoiceCallState.idle;
  String sessionId = '';
  String errorMsg = '';

  Future<void> requestCall({required String newSessionId}) async {
    try {
      sessionId = newSessionId;
      state = UiVoiceCallState.requesting;
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
    } catch (e) {
      errorMsg = e.toString();
      state = UiVoiceCallState.error;
      notifyListeners();
    }
  }
}

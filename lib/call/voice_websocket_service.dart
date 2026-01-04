import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

class VoiceWebSocketService {
  WebSocketChannel? _channel;
  final _controller = StreamController<String>.broadcast();

  bool _connected = false;
  bool get isConnected => _connected;

  Stream<String> get stream => _controller.stream;

  void connect({required String baseWs, required String voiceSessionId}) {
    // 이미 연결돼 있으면 재연결 안 함
    if (_channel != null) return;

    final uri = Uri.parse('$baseWs/ws/call-customer?voiceSessionId=$voiceSessionId');
    _channel = WebSocketChannel.connect(uri);
    _connected = true;

    _channel!.stream.listen(
          (data) {
        if (data != null) _controller.add(data.toString());
      },
      onError: (e) {
        _controller.addError(e);
      },
      onDone: () {
        disconnect();
      },
      cancelOnError: false,
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connected = false;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}

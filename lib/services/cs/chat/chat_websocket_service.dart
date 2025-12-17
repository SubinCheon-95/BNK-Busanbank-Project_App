import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ChatWebSocketService {
  WebSocketChannel? _channel;
  final StreamController<String> _controller = StreamController<String>.broadcast();

  bool get isConnected => _channel != null;

  Stream<String> get stream => _controller.stream;

  /// WebSocket 연결
  void connect() {
    if (_channel != null) return;

    final uri = Uri.parse('ws://10.0.2.2:8080/busanbank/ws/chat');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
          (data) {
        final msg = data?.toString() ?? '';
        _controller.add(msg);
        print('📥 WS 수신: $msg');
      },
      onError: (e) {
        _controller.addError(e);
      },
      onDone: () {
        print('🔌 WS onDone');
      },
      cancelOnError: false,
    );
    print('🔌 WebSocket 연결됨: $uri');
  }

  /// 메시지 보내기
  void sendText(String text) {
    if (_channel == null) {
      throw StateError("WebSocket 아직 연결 안 됨. connect() 먼저 호출.");
    }
    _channel!.sink.add(text);
    print("📤 보낸 메시지: $text");
  }

  /// 연결 종료
  void disconnect() {
    _channel?.sink.close(status.normalClosure);
    _channel = null;
    print('🔌 WebSocket 연결 종료됨.');
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}

import 'package:flutter/material.dart';

// 경로는 주인님 프로젝트 구조에 맞게 수정하세요.
import '../../../services/cs/chat/chat_api_service.dart';
import '../../../services/cs/chat/chat_websocket_service.dart';
import '../../../controller/chat_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController(
      api: ChatApiService(),
      ws: ChatWebSocketService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상담 테스트'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () async {
            // "상품 가입" 칩을 눌렀다고 가정
            await _controller.startChat("상품 가입");
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(),
            ),
            child: const Text("상품 가입 상담하기"),
          ),
        ),
      ),
    );
  }
}

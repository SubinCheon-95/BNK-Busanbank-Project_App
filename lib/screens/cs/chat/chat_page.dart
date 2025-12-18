import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';


import '../../../services/cs/chat/chat_api_service.dart';
import '../../../services/cs/chat/chat_websocket_service.dart';
import '../../../controller/chat_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ChatController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn && _controller == null) {
      _controller = ChatController(
        api: ChatApiService(),
        ws: ChatWebSocketService(),
        // userId/userNo 주입 로직 제거
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: Text('로그인 후 이용해 주세요.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('상담 테스트')),
      body: Center(
        child: GestureDetector(
          onTap: () async {
            await _controller!.startChat("상품 가입");
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

/*
  날짜: 2025/12/19
  내용: ai 챗봇 연동 페이지
  작성자: 오서정
*/
import 'package:flutter/material.dart';
import 'package:tkbank/main.dart';
import 'package:tkbank/models/chatbot_message.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';
import 'package:tkbank/screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/member/point_history_screen.dart';
import 'package:tkbank/screens/my_page/my_page_screen.dart';
import 'package:tkbank/screens/product/news_analysis_screen.dart';
import 'package:tkbank/screens/product/product_main_screen.dart';
import 'package:tkbank/services/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {

  static const String baseUrl = 'http://10.0.2.2:8080/busanbank/api';

  bool _showDialogue = false;
  bool _showIntro = true;
  bool _removeIntro = false;
  @override
  void initState() {
    super.initState();

    // 3초 후 fade-out
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _showIntro = false;
      });

      // fade-out 끝난 뒤 완전 제거
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _removeIntro = true;
        });
      });
    });
  }

  final Map<String, String> _actionLabels = {
    "MOVE_MY_PAGE": "마이페이지로 이동",
    "MOVE_PRODUCT": "상품으로 이동",
    "MOVE_POINT": "포인트로 이동",
    "MOVE_GAME": "금융게임으로 이동",
    "MOVE_CS": "고객센터로 이동",
    "MOVE_AI": "AI뉴스분석&상품추천로 이동"
  };

  void _handleAction(String code) {
    switch (code) {
      case "MOVE_MY_PAGE":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyPageScreen()),
        );
        break;
        
      case "MOVE_PRODUCT":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductMainScreen(baseUrl: baseUrl)),
        );
        break;

      case "MOVE_POINT":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PointHistoryScreen(baseUrl: baseUrl)),
        );
        break;

      case "MOVE_GAME":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameMenuScreen(baseUrl: baseUrl)),
        );
        break;

      case "MOVE_CS":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerSupportScreen(),),
        );
        break;

      case "MOVE_AI":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsAnalysisMainScreen(baseUrl: baseUrl),),
        );
        break;

    }
  }

  final TextEditingController _controller = TextEditingController();
  final ChatbotService _service = ChatbotService();

  final List<ChatbotMessage> _messages = [];
  bool _isLoading = false;

  bool _showInput = false;

  void _toggleInput() {
    setState(() => _showInput = !_showInput);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _controller.clear();
      _showInput = false;
    });

    try {
      final result = await _service.ask(text);

      setState(() {
        _messages.add(
          ChatbotMessage(
            text: result["answer"],
            isUser: false,
            actions: result["actions"],
          ),
        );
        _showDialogue = true;
      });

      // ⏳ 8초 뒤 답변 말풍선 숨기기
      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        setState(() {
          _showDialogue = false;
        });
      });

    } catch (e) {
      setState(() {
        _messages.add(
          ChatbotMessage(
            text: "오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
            isUser: false,
          ),
        );
        _showDialogue = true;
      });

      // 오류 메시지도 동일하게 숨김
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        setState(() {
          _showDialogue = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox.expand(
          child: Stack(
            children: [
          /// 🔙 뒤로가기
              Positioned(
                top: 40,
                left: 12,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
          const SizedBox(height: 12),


          // 🐧 인트로 말풍선
          if (!_removeIntro)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showIntro ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildIntroBubble(),
              ),
            ),



          // 💬 메시지 버튼 (펭귄맨 옆)
          Positioned(
            bottom: 200,
            left: MediaQuery.of(context).size.width / 2 + 36, // 👉 펭귄맨 옆으로 이동
            child: GestureDetector(
              onTap: _toggleInput,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 26,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ),

          // 💬 말풍선 영역
          Positioned(
            bottom: _showInput ?110 : 40,
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              opacity: _showDialogue ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: _buildDialogueArea(),
            ),
          ),

          // ⌨ 입력창 (숨김/표시)
          if (_showInput)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildInputBar(),
            ),

        ],
      ),
    ),

    );
  }

  Widget _buildDialogueArea() {
    if (_messages.isEmpty) return const SizedBox();

    final msg = _messages.last;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75), // 🔥 반투명
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "펭귄맨",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade700,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            msg.text,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),

          // 🎯 Quick Action 버튼
          if (msg.actions != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                children: msg.actions!.map((code) {
                  return _buildPenguinButton(code);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPenguinButton(String code) {
    return GestureDetector(
      onTap: () {
        _handleAction(code);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade100.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.lightBlue.shade300),
        ),
        child: Text(
          _actionLabels[code] ?? "이동",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ),
    );
  }
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "펭귄맨에게 말을 걸어보세요...",
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueGrey),
            onPressed: _sendMessage,
          )
        ],
      ),
    );
  }

  Widget _buildIntroBubble() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "펭귄맨",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "안녕! 나는 딸각은행의 펭귄맨이야 \n반가워!",
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

}

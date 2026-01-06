/*
  날짜: 2025/12/19
  내용: ai 챗봇 연동 페이지
  작성자: 오서정
  
  날짜: 2026/01/07
  내용: ai 챗봇 대화 연결 및 UI 전체 수정
  작성자: 천수빈
*/
import 'package:flutter/material.dart';
import 'package:tkbank/config/app_config.dart';
import 'package:tkbank/models/chatbot_message.dart';
import 'package:tkbank/screens/camera/vision_test_screen.dart';
import 'package:tkbank/screens/cs/cs_support_screen.dart';
import 'package:tkbank/screens/event/seed_event_screen.dart';
import 'package:tkbank/screens/game/game_menu_screen.dart';
import 'package:tkbank/screens/member/point_history_screen.dart';
import 'package:tkbank/screens/member/security_center_screen.dart';
import 'package:tkbank/screens/my_page/my_page_screen.dart';
import 'package:tkbank/screens/product/interest_calculator_screen.dart';
import 'package:tkbank/screens/product/news_analysis_screen.dart';
import 'package:tkbank/screens/product/product_main_screen.dart';
import 'package:tkbank/services/chatbot_service.dart';
import 'package:tkbank/theme/app_colors.dart';

class ChatbotScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatbotScreen({
    super.key,
    this.initialMessage,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  bool _showIntro = true;
  bool _removeIntro = false;

  late final DateTime _chatStartedAt;
  final ScrollController _scrollController = ScrollController();

  void _addIntroMessage() {
    _messages.add(
      ChatbotMessage(
        text: '안녕하세요! 딸깍은행 상담챗봇 딸깍이에요.\n궁금한 내용을 질문해 주시면 빠르게 안내해 드릴게요.',
        isUser: false,
      ),
    );
    _scrollToBottom();
  }

  @override
  void initState() {
    super.initState();

    _chatStartedAt = DateTime.now();

    // 딸깍이 예약 인사 먼저
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _addIntroMessage();
      });

      // AR에서 넘어온 질문이 있다면, 인사 후 답변
      if (widget.initialMessage != null &&
          widget.initialMessage!.trim().isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _sendMessageFromOutside(widget.initialMessage!);
        });
      }
    });
  }

  final Map<String, String> _actionLabels = {
    "MOVE_MY_PAGE": "마이페이지로 이동",
    "MOVE_PRODUCT": "상품으로 이동",
    "MOVE_POINT": "포인트로 이동",
    "MOVE_GAME": "금융게임으로 이동",
    "MOVE_CS": "고객센터로 이동",
    "MOVE_AI": "AI뉴스분석&상품추천로 이동",
    "MOVE_INTEREST_CALC": "금리계산기로 이동",
    "MOVE_SEED_EVENT": "금열매 이벤트로 이동",
    "MOVE_SECURITY_CENTER": "인증센터로 이동",
    "MOVE_VISION_EVENT": "로고 인증 이벤트로 이동",
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
          MaterialPageRoute(
              builder: (_) => ProductMainScreen(baseUrl: AppConfig.baseUrl)),
        );
        break;

      case "MOVE_POINT":
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PointHistoryScreen(baseUrl: AppConfig.baseUrl)),
        );
        break;

      case "MOVE_GAME":
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GameMenuScreen(baseUrl: AppConfig.baseUrl)),
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
          MaterialPageRoute(builder: (_) =>
              NewsAnalysisMainScreen(baseUrl: AppConfig.baseUrl),),
        );
        break;

      case "MOVE_INTEREST_CALC":
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => const InterestCalculatorScreen()));
        break;

      case "MOVE_SEED_EVENT":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SeedEventScreen()));
        break;

      case "MOVE_SECURITY_CENTER":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SecurityCenterScreen()));
        break;

      case "MOVE_VISION_EVENT":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VisionTestScreen()));
        break;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // AR에서 상담 챗봇으로 연결하기 (26.01.07 수빈)
  void _sendMessageFromOutside(String text) async {
    setState(() {
      _isLoading = true;

      // AR에서 넘어온 질문을 사용자 말풍선처럼 표시
      _messages.add(
        ChatbotMessage(
          text: text,
          isUser: true,
        ),
      );
    });

    _scrollToBottom();

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
        _isLoading = false;
      });

      _scrollToBottom();

    } catch (e) {
      setState(() {
        _messages.add(
          ChatbotMessage(
            text: "해당 내용은 바로 안내드리기 어려워요.\n조금 더 구체적으로 질문해 주시면 도와드릴게요 😊",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  // 무조건 맨 아래로 자동 스크롤 (26.01.07 수빈)
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
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

    if (text.length < 2) {
      setState(() {
        _messages.add(
          ChatbotMessage(
            text: "조금만 더 자세히 말씀해 주시면 제가 더 잘 도와드릴 수 있어요 😊",
            isUser: false,
          ),
        );
      });
      return;
    }

    final invalidPatterns = ['ㅋㅋ', 'ㅎㅎ', '...', '???'];

    if (invalidPatterns.any((p) => text.contains(p))) {
      setState(() {
        _messages.add(
          ChatbotMessage(
            text: "앗, 이 표현은 제가 이해하기 조금 어려워요. \n다른 방식으로 한 번만 말씀해 주세요!",
            isUser: false,
          ),
        );
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;

      // 사용자 말풍선 추가
      _messages.add(
        ChatbotMessage(
          text: text,
          isUser: true,
        ),
      );

      _controller.clear();
    });

    _scrollToBottom(); //

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
        _isLoading = false;
      });

      _scrollToBottom(); //

    } catch (e) {
      String errorMessage;

      if (e.toString().contains('SocketException')) {
        // 네트워크 오류
        errorMessage =
        "지금 인터넷 연결이 불안정한 것 같아요. \n잠시 후 다시 시도해 주세요!";
      } else if (e.toString().contains('timeout')) {
        // 서버 응답 지연
        errorMessage =
        "답변이 조금 늦어지고 있어요. \n잠시만 기다렸다가 다시 질문해 주세요!";
      } else {
        // 기타 (AI 이해 불가 포함)
        errorMessage =
        "이 질문은 제가 바로 답변하기 어려워요. 🐧\n조금만 다르게 질문해 주실 수 있을까요?";
      }

      setState(() {
        _messages.add(
          ChatbotMessage(
            text: errorMessage,
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: Stack(
        children: [
          // 본문
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              _buildChatTitle(),   // 타이틀
              _buildDateDivider(), // 날짜

              Expanded(
                child: _buildChatList(),
              ),
            ],
          ),

          // 뒤로가기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                size: 34,
                color: AppColors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 하단 입력창
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: const Text(
        'AI 상담 챗봇',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDateDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${_chatStartedAt.year}년 ${_chatStartedAt.month}월 ${_chatStartedAt.day}일',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gray4,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        140, // 입력창 높이만큼 여유 공간 줘야함
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];

        // 사용자 메시지
        if (msg.isUser) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 딸깍이 메시지
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 딸깍이 이미지
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage(
                      'assets/images/penguinman_smile.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 말풍선
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '딸깍이 · AI 상담원',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                    if (msg.actions != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          children: msg.actions!.map((code) {
                            return OutlinedButton(
                              onPressed: () => _handleAction(code),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                side: const BorderSide(
                                  color: AppColors.primary, // 테두리
                                  width: 1,
                                ),
                                foregroundColor: AppColors.primary, // 텍스트 색
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                _actionLabels[code]!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );

                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 하단 입력창 (26.01.07 수빈)
  Widget _buildInputBar() {
    final hasText = _controller.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 15,
        bottom: MediaQuery.of(context).padding.bottom + 15,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 입력창
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '딸깍이에게 메시지를 입력해 주세요',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send 버튼
          Container(
            decoration: BoxDecoration(
              color: hasText ? AppColors.primary : AppColors.gray3,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: AppColors.white,
              onPressed: hasText ? _sendMessage : null,
            ),
          ),
        ],
      ),
    );
  }
}
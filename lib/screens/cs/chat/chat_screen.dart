import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../controller/chat_controller.dart';
import '../../../models/ui_message.dart';

class ChatScreen extends StatefulWidget {
  final String? initialInquiryType;
  final ChatController controller; // ✅ 상위에서 주입

  const ChatScreen({
    super.key,
    required this.controller,
    this.initialInquiryType,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

enum _LeaveAction { stay, leaveKeep, end }

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _chatController;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isChatStarted = false;
  bool _isEnded = false;
  bool _isAgentTyping = false;
  Timer? _typingTimer;

  StreamSubscription<String>? _wsSub;

  final List<String> _inquiryTypes = const [
    '예금', '카드', '대출', '펀드', '외환', '신탁', '보험', '상품', '분실',
  ];

  // ✅ 메시지는 화면이 아니라 “컨트롤러 캐시”를 그대로 사용 → 재진입 복원
  List<UiMessage> get _messages => _chatController.cachedMessages;

  @override
  void initState() {
    super.initState();

    _chatController = widget.controller;

    // ✅ WS 수신 구독 (이 화면에서만 1번)
    _wsSub = _chatController.stream.listen(
      _onWsData,
      onError: (e) {
        if (!mounted) return;
        setState(() => _messages.add(UiMessage(UiKind.system, '오류: $e')));
        _scrollToBottom();
      },
    );

    // ✅ 재진입 처리 + initialInquiryType 처리
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resumeIfNeeded();

      // 초기 진입 타입 있으면 자동 시작(세션 없을 때만)
      if (widget.initialInquiryType != null && _chatController.sessionId == null) {
        await _handleSelectInquiryType(widget.initialInquiryType!);
      }

      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _wsSub?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --------------------------
  // Resume: 세션 살아있으면 이어서 연결 + UI 상태 세팅
  // --------------------------
  Future<void> _resumeIfNeeded() async {
    if (_chatController.sessionId == null) return;

    setState(() {
      _isChatStarted = true;
      _isEnded = false;
    });

    // 소켓이 끊겼으면 재연결 + ENTER 전송
    if (!_chatController.ws.isConnected) {
      _chatController.ws.connect();
      _chatController.ws.sendText(jsonEncode({
        "type": "ENTER",
        "sessionId": _chatController.sessionId,
        "senderType": _chatController.senderType,
        "senderId": _chatController.senderId,
      }));
    }

    // 안내 메시지(중복 방지: 이미 같은 문구가 마지막이면 추가 안 함)
    final last = _messages.isNotEmpty ? _messages.last.text : '';
    const hint = '진행 중 상담을 이어서 연결했습니다.';
    if (last != hint) {
      setState(() => _messages.add(UiMessage(UiKind.system, hint)));
    }
  }

  // --------------------------
  // WS 수신 처리
  // --------------------------
  void _onWsData(String raw) {
    Map<String, dynamic>? obj;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) obj = decoded;
    } catch (_) {
      obj = null;
    }

    if (obj == null) {
      setState(() => _messages.add(UiMessage(UiKind.agent, raw)));
      _scrollToBottom();
      return;
    }

    final type = (obj['type'] ?? '').toString();
    final senderType = (obj['senderType'] ?? '').toString(); // USER/AGENT
    final message = (obj['message'] ?? '').toString();

    if (type == 'TYPING' && senderType.toUpperCase() == 'AGENT') {
      final typing = obj['isTyping'] == true || obj['typing'] == true;

      setState(() => _isAgentTyping = typing);
      _scrollToBottom();

      // ✅ stop 신호 누락 대비 자동 종료(웹이랑 동일한 안전장치)
      _typingTimer?.cancel();
      if (typing) {
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _isAgentTyping = false);
        });
      }
      return;
    }

    if (type == 'CHAT') {
      // ✅ 상담원 메시지 오면 typing 종료
      if (senderType.toUpperCase() == 'AGENT') {
        _typingTimer?.cancel();
        setState(() => _isAgentTyping = false);
      }

      // 서버가 USER 메시지를 에코로 다시 보내면 중복이라 무시
      if (senderType.toUpperCase() == 'USER') return;

      setState(() => _messages.add(UiMessage(UiKind.agent, message)));
      _scrollToBottom();
      return;
    }

    if (type == 'SYSTEM') {
      setState(() => _messages.add(UiMessage(UiKind.system, message.isEmpty ? '안내 메시지' : message)));
      _scrollToBottom();
      return;
    }

    if (type == 'END') {
      _typingTimer?.cancel();
      setState(() {
        _isAgentTyping = false; // ✅ 종료 시 typing도 내림
        _messages.add(UiMessage(UiKind.system, message.isEmpty ? '상담이 종료되었습니다.' : message));
        _isEnded = true;
      });
      _scrollToBottom();
      return;
    }

    setState(() => _messages.add(UiMessage(UiKind.system, '[${type.isEmpty ? "UNKNOWN" : type}] $message')));
    _scrollToBottom();
  }

  // --------------------------
  // 상담 시작 (유형 선택)
  // --------------------------
  Future<void> _handleSelectInquiryType(String type) async {
    if (_isEnded) return;

    // 이미 세션이 있으면 굳이 새로 만들지 않음(이어하기 상태)
    if (_chatController.sessionId != null) {
      setState(() => _isChatStarted = true);
      return;
    }

    final ok = await _chatController.startChat(type);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상담 세션 생성에 실패했습니다.')),
      );
      return;
    }

    setState(() {
      _isChatStarted = true;
      _messages.add(UiMessage(UiKind.me, type));
    });
    _scrollToBottom();
  }

  // --------------------------
  // 메시지 전송
  // --------------------------
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (!_isChatStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 상담유형을 선택해 주세요.')),
      );
      return;
    }

    if (_isEnded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 종료된 상담입니다.')),
      );
      return;
    }

    // 이어하기 상태인데 소켓이 끊겼으면 재연결 + ENTER
    if (!_chatController.ws.isConnected && _chatController.sessionId != null) {
      _chatController.ws.connect();
      _chatController.ws.sendText(jsonEncode({
        "type": "ENTER",
        "sessionId": _chatController.sessionId,
        "senderType": _chatController.senderType,
        "senderId": _chatController.senderId,
      }));
    }

    _chatController.sendChatMessage(text);

    setState(() => _messages.add(UiMessage(UiKind.me, text)));
    _textController.clear();
    _scrollToBottom();
  }

  // --------------------------
  // 뒤로가기: 상담 유지로 나가기 / 상담 종료 선택
  // --------------------------
  Future<_LeaveAction> _showLeaveDialog() async {
    if (_isEnded) return _LeaveAction.leaveKeep;

    final result = await showDialog<_LeaveAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('채팅을 나갈까요?'),
        content: const Text('상담을 유지한 채로 나가거나, 상담을 종료할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_LeaveAction.stay),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_LeaveAction.leaveKeep),
            child: const Text('나가기(상담 유지)'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(_LeaveAction.end),
            child: const Text('상담 종료'),
          ),
        ],
      ),
    );

    return result ?? _LeaveAction.stay;
  }

  Future<void> _handleBackPressed() async {
    final action = await _showLeaveDialog();
    if (action == _LeaveAction.stay) return;

    if (action == _LeaveAction.end) {
      _chatController.requestEndChat();

      // ✅ 세션만 종료 처리하고, 화면/캐시는 남겨서 마지막 대화 확인 가능
      _chatController.disconnectAndReset(clearCache: false);

      if (!mounted) return;
      setState(() => _isEnded = true);

      // ✅ 종료 후 화면은 팝(기존처럼)
      Navigator.of(context).pop();
      return;
    }

    // ✅ 나가기(상담 유지): 소켓만 끊고 sessionId/캐시는 유지
    _chatController.detach();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // X 버튼: 종료 전용
  Future<void> _handleEndPressed() async {
    if (_isEnded) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('상담을 종료할까요?'),
        content: const Text('종료하면 채팅이 더 이상 진행되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('종료'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    _chatController.requestEndChat();
    _chatController.disconnectAndReset(clearCache: false);

    if (!mounted) return;
    Navigator.of(context).pop();
  }


  // --------------------------
  // Scroll util
  // --------------------------
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _korWeekday(int weekday) {
    const map = ['월', '화', '수', '목', '금', '토', '일'];
    return map[(weekday - 1).clamp(0, 6)];
  }

  Widget _buildDateBar() {
    final now = DateTime.now();
    final label =
        '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}(${_korWeekday(now.weekday)})';

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.pink.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.pink.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAgentAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Icon(
        Icons.support_agent,
        color: Colors.pink.shade300,
        size: 20,
      ),
    );
  }

  Widget _buildIntroSection() {
    final colorScheme = Theme.of(context).colorScheme;

    // 진행중 세션이면 칩 숨김(이어하기 UX)
    final showChips = !_isChatStarted && !_isEnded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAgentAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Text(
                  '고객님 반갑습니다.\n아래의 문의유형 중 상담을 원하시는 업무를 선택해 주세요 ^^',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (showChips)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _inquiryTypes.map((type) {
              return ChoiceChip(
                label: Text(type),
                selected: false,
                onSelected: (_) => _handleSelectInquiryType(type),
                selectedColor: Colors.pink.shade50,
                labelStyle: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w400,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    if (!_isAgentTyping) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAgentAvatar(),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: const _TypingDots(
            text: '상담사가 입력 중',
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(UiMessage m) {
    if (m.kind == UiKind.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            m.text,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      );
    }

    if (m.kind == UiKind.me) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            m.text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      );
    }

    // agent
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAgentAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: Text(
              m.text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pink = Colors.pink;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: pink,
          foregroundColor: Colors.white,
          title: const Text('Talk상담', style: TextStyle(fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPressed,
          ),
          actions: [
            TextButton.icon(
              onPressed: _handleEndPressed,
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              label: const Text('상담 종료', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xfff7f7f7),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                children: [
                  _buildDateBar(),
                  _buildIntroSection(),
                  const SizedBox(height: 8),
                  ..._messages.map(_buildBubble),
                  _buildTypingIndicator(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: _isChatStarted && !_isEnded,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요.',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: pink,
                    onPressed: (_isChatStarted && !_isEnded) ? _sendMessage : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  final String text;
  final Duration interval;

  const _TypingDots({
    required this.text,
    this.interval = const Duration(milliseconds: 350),
  });

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> {
  Timer? _timer;
  int _step = 0; // 0..3

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % 4);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.'.padLeft(_step, ' ').padRight(3, ' ');
    // _step=0 => "   ", 1=>" . ", 2=>" ..", 3=>"..."
    return Text(
      '${widget.text}$dots',
      style: const TextStyle(fontSize: 13, color: Colors.black54),
    );
  }
}


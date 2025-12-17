import 'package:tkbank/screens/cs/faq_screen.dart';
import 'package:flutter/material.dart';

import '../../../controller/chat_controller.dart';
import '../../services/cs/chat/chat_api_service.dart';
import '../../services/cs/chat/chat_websocket_service.dart';

import 'chat/chat_screen.dart';

/// 고객센터 > 상담 메인 페이지
class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  late final ChatController _chatController;

  // 진행중 상담 여부(세션ID 존재 + 종료 아님)
  bool get _hasActiveSession => _chatController.sessionId != null;

  @override
  void initState() {
    super.initState();

    // ✅ 컨트롤러를 “여기서 1번만” 만들고 유지 (재진입/이어하기 핵심)
    _chatController = ChatController(
      api: ChatApiService(),
      ws: ChatWebSocketService(),
    );

    // TODO(선택): 앱 재실행 후에도 이어하기 원하면
    // SharedPreferences 등에 sessionId 저장/복원 로직을 여기에 추가하세요.
  }

  @override
  void dispose() {
    // ⚠️ 앱 전체에서 유지하고 싶으면 여기서 dispose 하지 말고
    // 앱 종료/로그아웃 시점에만 정리하는 구조로 바꿔도 됩니다.
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _openChat(BuildContext context, {String? inquiryType}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          controller: _chatController,     // ✅ 주입
          initialInquiryType: inquiryType, // null이면 화면에서 선택
        ),
      ),
    );

    // ChatScreen에서 종료/나가기 후 돌아오면 상태 갱신
    if (!mounted) return;
    setState(() {});
  }

  void _openFaq(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaqScreen()),
    );
  }

  void _openOneToOne(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('1:1 문의 화면은 추후 연결 예정입니다.')),
    );
  }

  void _openChatHistory(BuildContext context) {
    // TODO: “지난 상담내역” 화면으로 이동(세션 목록 API 붙이면 여기서 보여주기)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('지난 상담내역은 추후 연결 예정입니다.')),
    );
  }

  void _callCenter(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전화 상담 연결은 추후 구현 예정입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('고객센터')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 상단 안내 영역
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent, size: 40, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '무엇을 도와드릴까요?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '자주 묻는 질문부터 1:1 채팅 상담까지\n원하시는 상담 방식을 선택해 주세요.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ 진행 중 상담 카드(세션이 살아있을 때만 노출)
          if (_hasActiveSession)
            Card(
              elevation: 1,
              color: Colors.pink.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: const Text('진행 중인 상담이 있습니다'),
                subtitle: Text('세션 ID: ${_chatController.sessionId}  ·  이어서 상담하기'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openChat(context),
              ),
            ),

          if (_hasActiveSession) const SizedBox(height: 16) else const SizedBox(height: 16),

          // 주요 메뉴 카드 (FAQ, 1:1문의, 지난 상담내역)
          Text('상담/문의', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('자주 묻는 질문(FAQ)'),
                  subtitle: const Text('자주 문의되는 내용을 먼저 확인해 보세요.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openFaq(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('1:1 문의'),
                  subtitle: const Text('문의 내용을 남겨주시면 순차적으로 답변드립니다.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openOneToOne(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('지난 상담내역'),
                  subtitle: const Text('종료된 상담 내역을 확인할 수 있습니다.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openChatHistory(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 실시간 상담 영역 (채팅, 전화)
          Text('실시간 상담', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(_hasActiveSession ? '채팅 상담 (이어하기)' : '채팅 상담'),
                  subtitle: Text(_hasActiveSession
                      ? '진행 중 상담으로 다시 연결합니다.'
                      : '상담원과 실시간 채팅으로 문의하세요.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openChat(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.call_outlined),
                  title: const Text('전화 상담'),
                  subtitle: const Text('고객센터로 바로 전화 연결됩니다.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _callCenter(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            '※ 상담 가능 시간\n  · 평일 09:00 ~ 18:00 (주말/공휴일 휴무)\n'
                '※ 상담 내용은 서비스 품질 향상을 위해 기록될 수 있습니다.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

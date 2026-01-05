import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/call/call_screen.dart';
import 'package:tkbank/screens/cs/counsel_history_hub_screen.dart';
import 'package:tkbank/screens/cs/email/email_counsel_form_screen.dart';

import 'package:tkbank/screens/cs/faq_screen.dart';
import 'package:tkbank/screens/walk/step_counter_page.dart';

import '../../../controller/chat_controller.dart';
import '../../../services/cs/chat/chat_api_service.dart';
import '../../../services/cs/chat/chat_websocket_service.dart';
import '../../../providers/auth_provider.dart';

import 'chat/chat_screen.dart';

/// 고객센터 > 상담 메인 페이지 (풀메뉴 + 로그인 연동)
class CustomerSupportScreen extends StatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  ChatController? _chatController;

  bool get _hasActiveSession => _chatController?.sessionId != null;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _openChat(BuildContext context, {String? inquiryType}) async {
    final auth = context.read<AuthProvider>();

    // 🔐 로그인 체크
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // ✅ 로그인 돼있으면 여기서 무조건 컨트롤러 생성(지연 생성)
    _chatController ??= ChatController(
      api: ChatApiService(),
      ws: ChatWebSocketService(),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          controller: _chatController!,
          initialInquiryType: inquiryType,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {}); // 진행중 상담 카드 등 갱신
  }

  void _openFaq(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaqScreen()),
    );
  }

  void _openOneToOne(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmailCounselFormScreen()),
    );
  }

  void _openChatHistory(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CounselHistoryHubScreen()),
    );
  }

  void _callCenter(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('전화 상담 연결은 추후 구현 예정입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
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
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '자주 묻는 질문부터 1:1 채팅 상담까지\n원하시는 상담 방식을 선택해 주세요.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 로그인 안내
          if (!isLoggedIn)
            Card(
              elevation: 1,
              color: Colors.amberAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('로그인이 필요합니다'),
                subtitle: Text('채팅 상담 및 상담내역 확인은 로그인 후 이용 가능합니다.'),
              ),
            ),

          const SizedBox(height: 12),

          // 진행 중 상담
          if (isLoggedIn && _hasActiveSession)
            Card(
              elevation: 1,
              color: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: const Text('진행 중인 상담이 있습니다'),
                subtitle: Text('세션 ID: ${_chatController!.sessionId} · 이어서 상담하기'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  debugPrint('tap: 진행중 상담');
                  _openChat(context);
                },
              ),
            ),

          const SizedBox(height: 16),

          // 상담/문의
          Text('상담/문의', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),

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
                  onTap: () {
                    debugPrint('tap: FAQ');
                    _openFaq(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('1:1 문의'),
                  subtitle: const Text('문의 내용을 남겨주시면 순차적으로 답변드립니다.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    debugPrint('tap: 1:1 문의');
                    _openOneToOne(context);
                  },
                ),
                const Divider(height: 1),

                // ✅ 변경됨: 로그인 여부와 무관하게 "항상 눌리게"
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('지난 상담내역'),
                  subtitle: const Text('종료된 상담 내역을 확인할 수 있습니다.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    debugPrint('tap: 지난 상담내역');
                    _openChatHistory(context);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 실시간 상담
          Text('실시간 상담', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                // ✅ 변경됨: 로그인 여부와 무관하게 "항상 눌리게"
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(_hasActiveSession ? '채팅 상담 (이어하기)' : '채팅 상담'),
                  subtitle: Text(
                    _hasActiveSession ? '진행 중 상담으로 다시 연결합니다.' : '상담원과 실시간 채팅으로 문의하세요.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    debugPrint('tap: 채팅상담');
                    _openChat(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.call_outlined),
                  title: const Text('전화 상담'),
                  subtitle: const Text('고객센터로 바로 전화 연결됩니다.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    debugPrint('tap: 전화상담');

                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CallScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 만보기
          Text('만보기', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.directions_walk),
                  title: const Text('만보기'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    debugPrint('tap: 만보기');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StepCounterPage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

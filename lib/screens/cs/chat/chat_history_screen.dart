import 'package:flutter/material.dart';
import 'package:tkbank/models/chat_session_summary.dart';
import 'package:tkbank/screens/cs/chat/chat_history_detail_screen.dart';
import 'package:tkbank/services/cs/chat/chat_api_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  /// Hub(Tab) 안에서 쓰면 AppBar 중복되니 false 추천
  final bool showAppBar;

  /// 문의유형(inquiryType) 표시는 “작게” 옵션
  final bool showInquiryTypeLabel;

  const ChatHistoryScreen({
    super.key,
    this.showAppBar = false,
    this.showInquiryTypeLabel = true,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final _scroll = ScrollController();
  late final ChatApiService _api;

  final List<ChatSessionSummary> _items = [];
  String? _cursor;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _api = ChatApiService();
    _load(first: true);

    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool first = false}) async {
    if (_loading) return;
    if (!first && !_hasMore) return;

    setState(() => _loading = true);

    try {
      final page = await _api.fetchChatHistorySessions(
        cursor: first ? null : _cursor,
        size: 20,
      );

      setState(() {
        if (first) _items.clear();
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _hasMore = page.nextCursor != null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상담내역을 불러오지 못했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$m.$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
      onRefresh: () => _load(first: true),
      child: ListView.separated(
        controller: _scroll,
        itemCount: _items.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          if (i == _items.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : (!_hasMore
                    ? const Text('마지막 내역입니다.')
                    : const SizedBox.shrink()),
              ),
            );
          }

          final s = _items[i];
          final isActive = s.status == ChatSessionStatus.active;

          // ✅ type(문의유형) 크게 보이는 느낌 제거: title을 고정
          final titleText = '채팅 상담';

          // ✅ lastMessage가 있으면 우선 표시, 없으면 상태 문구
          final baseSubtitle = (s.lastMessage?.isNotEmpty == true)
              ? s.lastMessage!
              : (isActive ? '진행 중 상담' : '종료된 상담');

          // ✅ inquiryType은 “작게” 옵션(원하면 숨길 수 있음)
          final inquiryLabel = (widget.showInquiryTypeLabel &&
              s.inquiryType.trim().isNotEmpty)
              ? '문의유형: ${s.inquiryType}'
              : null;

          return ListTile(
            leading: Icon(isActive ? Icons.forum_outlined : Icons.history),
            title: Text(titleText),
            subtitle: inquiryLabel == null
                ? Text(
              baseSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baseSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  inquiryLabel,
                  style:
                  const TextStyle(fontSize: 12, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? '진행중' : '종료',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? Colors.green.shade700
                          : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _fmt(s.lastMessageAt ?? s.startedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatHistoryDetailScreen(
                    api: _api, // ✅ 같은 인스턴스 전달
                    sessionId: s.sessionId,
                    title: '채팅 상담', // ✅ 상세 타이틀도 고정
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    // Hub(Tab) 안이면 AppBar를 여기서 또 만들면 중복됩니다.
    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('채팅 상담 내역')),
      body: body,
    );
  }
}


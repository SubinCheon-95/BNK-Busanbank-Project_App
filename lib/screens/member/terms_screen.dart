/*
  날짜 : 2025/12/15
  내용 : 약관 페이지 추가
  작성자 : 오서정
*/
import 'package:flutter/material.dart';
import 'package:tkbank/models/term.dart';
import 'package:tkbank/services/member_service.dart';
import 'term_webview_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  final MemberService _memberService = MemberService();
  late Future<List<Term>> _termsFuture;

  // 약관 동의 상태
  final Map<int, bool> _agreeMap = {};
  bool _allChecked = false;

  @override
  void initState() {
    super.initState();
    _termsFuture = _memberService.fetchTerms();
  }

  void _openTerm(int termNo) {
    final url =
        'http://10.0.2.2:8080/busanbank/member/term/$termNo';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TermWebViewScreen(url: url),
      ),
    );
  }

  void _updateAllChecked() {
    _allChecked = _agreeMap.values.every((v) => v == true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 동의'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Term>>(
        future: _termsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('약관 정보를 불러올 수 없습니다.'),
            );
          }

          final terms = snapshot.data!;

          // 최초 진입 시 동의 상태 초기화
          for (var term in terms) {
            _agreeMap.putIfAbsent(term.termNo, () => false);
          }

          return Column(
            children: [
              // 전체 동의
              CheckboxListTile(
                value: _allChecked,
                onChanged: (value) {
                  setState(() {
                    _allChecked = value ?? false;
                    for (var term in terms) {
                      _agreeMap[term.termNo] = _allChecked;
                    }
                  });
                },
                title: const Text(
                  '약관 전체동의',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const Divider(height: 1),

              // 약관 목록
              Expanded(
                child: ListView.builder(
                  itemCount: terms.length,
                  itemBuilder: (context, index) {
                    final term = terms[index];

                    return ListTile(
                      leading: Checkbox(
                        value: _agreeMap[term.termNo],
                        onChanged: (value) {
                          setState(() {
                            _agreeMap[term.termNo] = value ?? false;
                            _updateAllChecked();
                          });
                        },
                      ),
                      title: Text(
                        '(필수) ${term.termTitle}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _openTerm(term.termNo),
                      ),
                    );
                  },
                ),
              ),

              // 하단 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _allChecked
                            ? () {
                          Navigator.pushNamed(context, '/register');
                        }
                            : null,
                        child: const Text('동의'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

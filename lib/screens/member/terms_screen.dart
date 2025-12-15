/*
  날짜 : 2025/12/15
  내용 : 약관 페이지 추가
  작성자 : 오서정
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/models/term.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/screens/member/register_screen.dart';
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

  static const Color primaryPurple = Color(0xFF6A1B9A);
  static const Color bgGray = Color(0xFFF5F6F8);

  @override
  void initState() {
    super.initState();
    _termsFuture = _memberService.fetchTerms();
  }

  void _openTerm(int termNo) {
    final url = 'http://10.0.2.2:8080/busanbank/member/term/$termNo';

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
      backgroundColor: bgGray,
      appBar: AppBar(
        title: const Text('약관 동의'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  value: _allChecked,
                  activeColor: primaryPurple,
                  onChanged: (value) {
                    setState(() {
                      _allChecked = value ?? false;
                      for (var term in terms) {
                        _agreeMap[term.termNo] = _allChecked;
                      }
                    });
                  },
                  title: const Text(
                    '약관 전체 동의',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),


              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: terms.length,
                  itemBuilder: (context, index) {
                    final term = terms[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openTerm(term.termNo),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _agreeMap[term.termNo],
                              activeColor: primaryPurple,
                              onChanged: (value) {
                                setState(() {
                                  _agreeMap[term.termNo] = value ?? false;
                                  _updateAllChecked();
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '(필수)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    term.termTitle,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),


      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5E5E5)),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _allChecked
                ? () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => RegisterScreen()),
              );
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              disabledBackgroundColor: primaryPurple.withOpacity(0.3),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '동의하고 계속하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

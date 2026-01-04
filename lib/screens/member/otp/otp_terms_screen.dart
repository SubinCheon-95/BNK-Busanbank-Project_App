/*
  날짜: 2025/01/04
  내용: otp등록 약관 화면
  작성자: 오서정
*/
import 'package:flutter/material.dart';
import 'package:tkbank/models/term.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/screens/member/register/term_webview_screen.dart';

// ✅ OTP 등록 화면(원래 가던 화면)으로 바꿔 끼우기
import 'package:tkbank/screens/member/otp/otp_register_screen.dart';


class OtpTermsScreen extends StatefulWidget {
  const OtpTermsScreen({super.key});

  @override
  State<OtpTermsScreen> createState() => _OtpTermsScreenState();
}

class _OtpTermsScreenState extends State<OtpTermsScreen> {
  final MemberService _memberService = MemberService();
  late Future<List<Term>> _termsFuture;

  final Map<int, bool> _agreeMap = {};
  bool _allChecked = false;

  static const Color primaryPurple = Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    _termsFuture = _memberService.fetchTerms();
  }

  void _openTerm(int termNo) {
    // ✅ term 상세 조회 엔드포인트가 어디인지에 맞춰 통일
    final url = 'http://10.0.2.2:8080/busanbank/member/term/$termNo';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TermWebViewScreen(url: url)),
    );
  }

  void _updateAllChecked() {
    _allChecked = _agreeMap.values.isNotEmpty && _agreeMap.values.every((v) => v == true);
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디지털OTP 약관 동의'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _allChecked
                ? () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OtpRegisterScreen()),
                // 또는 OtpIssueIntroScreen() 등
              );
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              disabledBackgroundColor: primaryPurple.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              '다음',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: FutureBuilder<List<Term>>(
          future: _termsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(child: Text('약관 정보를 불러올 수 없습니다.'));
            }

            final all = snapshot.data!;
            final terms = all.where((t) => t.termType == '03').toList();
            for (var term in terms) {
              _agreeMap.putIfAbsent(term.termNo, () => false);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      const Text(
                        '디지털 OTP 발급을 위해',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        '약관 동의가 필요해요.',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '서비스 이용을 위해 약관에 동의해주세요',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),

                      const SizedBox(height: 24),

                      _card(
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
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    itemCount: terms.length,
                    itemBuilder: (context, index) {
                      final term = terms[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _card(
                          child: InkWell(
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
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    term.termTitle,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
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
      ),
    );
  }
}

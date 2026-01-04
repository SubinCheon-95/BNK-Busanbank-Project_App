/*
  날짜: 2026/01/02
  내용: OCR 등록 완료 화면
  이름: 오서정
  수정: 2025/01/04 - UI 수정 - 작성자: 오서정
*/

import 'package:flutter/material.dart';

const Color bnkPrimary = Color(0xFF6A1B9A);
const Color bnkGrayText = Color(0xFF6B7280);

class OtpIssueCompleteScreen extends StatelessWidget {
  final int oneLimit; // 1회한도
  final int dayLimit; // 1일한도

  const OtpIssueCompleteScreen({
    super.key,
    required this.oneLimit,
    required this.dayLimit,
  });

  String _money(int v) {
    // 간단 포맷 (원하면 intl NumberFormat으로 바꿔도 됨)
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    return '${buf.toString()}원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디지털OTP(재)발급'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 56),
          Icon(Icons.check_circle, size: 84, color: bnkPrimary),
          const SizedBox(height: 18),
          const Text(
            '디지털OTP 발급이\n완료되었습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('한도 변경 가능 금액',
                    style: TextStyle(fontSize: 13, color: bnkGrayText)),
                const SizedBox(height: 10),
                const Divider(height: 1),

                const SizedBox(height: 14),
                _row('1회한도', _money(oneLimit)),
                const SizedBox(height: 10),
                _row('1일한도', _money(dayLimit)),
                const SizedBox(height: 14),
                const Divider(height: 1),
              ],
            ),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ 여기서 SecurityCenterScreen으로 복귀 + 결과 전달
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bnkPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('확인', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String left, String right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(left, style: const TextStyle(fontSize: 14)),
        Text(right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

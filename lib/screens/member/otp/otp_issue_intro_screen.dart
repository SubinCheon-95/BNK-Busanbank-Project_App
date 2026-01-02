/*
  날짜: 2025/12/29
  내용: OTP 등록 안내 화면
  이름: 오서정
*/

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tkbank/screens/member/otp/otp_register_screen.dart';
import 'package:tkbank/screens/member/pin/pin_register_screen.dart';
const Color bnkPrimary = Color(0xFF6A1B9A);   // 메인 보라
const Color bnkPrimarySoft = Color(0xFFF3E5F5); // 연보라 배경
const Color bnkGrayText = Color(0xFF6B7280);
const Color bnkCardBg = Colors.white;

class OtpIssueIntroScreen extends StatefulWidget {
  const OtpIssueIntroScreen({super.key});

  @override
  State<OtpIssueIntroScreen> createState() => _OtpIssueIntroScreenState();
}

class _OtpIssueIntroScreenState extends State<OtpIssueIntroScreen> {
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🔐 아이콘
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: bnkPrimarySoft,
                      child: const Icon(
                        Icons.phonelink_lock,
                        size: 40,
                        color: bnkPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 메인 설명
                  const Center(
                    child: Text(
                      '디지털OTP PIN번호만으로\n금융거래를 이용할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      '보안매체(OTP, 보안카드) 없이\n등록한 PIN번호로 인증',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),

                  _sectionTitle('이용대상'),
                  _bullet('만 14세 이상 개인고객'),

                  const SizedBox(height: 20),

                  _sectionTitle('발급방법'),
                  _bullet('모바일뱅킹에서 비대면 실명확인 후 발급'),
                  _bullet('본인명의 휴대전화, 신분증 필요'),

                  const SizedBox(height: 20),

                  _sectionTitle('발급비용'),
                  _bullet('무료'),

                  const SizedBox(height: 24),
                  const Divider(thickness: 1),

                  const SizedBox(height: 16),

                  Row(
                    children: const [
                      Icon(
                        Icons.error_outline,
                        color: bnkPrimary,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '유의사항',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _notice(
                    '디지털OTP는 본인명의 휴대폰에서만 (재)발급 가능하며 발급한 기기에서만 이용 가능합니다.',
                  ),
                  _notice(
                    '휴대폰번호가 변경된 경우 모바일뱅킹 또는 가까운 영업점을 방문하여 휴대폰 번호를 변경 후 발급하시기 바랍니다.',
                  ),
                  _notice(
                    '휴대폰 기기 또는 휴대폰 번호가 변경된 경우 (재)발급 받으셔야 합니다.',
                  ),
                  _notice(
                    '디지털OTP는 딸깍은행만 이용 가능하며 기존 사용하시던 보안카드는 폐기되고, OTP는 이용 해지됩니다.',
                  ),
                  _notice(
                    '텔레뱅킹 이용 고객은 디지털OTP 발급이 불가합니다.',
                  ),

                ],
              ),
            ),
          ),


          // 🔴 하단 버튼 영역
          // 🔴 하단 버튼 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: bnkGrayText.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // ⭐ 둥근 네모
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: bnkGrayText,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bnkPrimary,
                        elevation: 0, // 금융앱은 그림자 거의 안 씀
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // ⭐ 둥근 네모
                        ),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OtpRegisterScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          Navigator.pop(context, true); // OtpIssueIntroScreen으로 전달
                        }
                      },
                      child: const Text(
                        '(재)발급',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('• $text'),
    );
  }


  Widget _notice(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              color: bnkGrayText,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: bnkGrayText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tkbank/screens/member/otp/otp_pin_register_screen.dart';
import 'package:tkbank/screens/member/pin_auth_screen.dart';
import 'package:tkbank/screens/member/security_center_screen.dart';
const Color bnkPrimary = Color(0xFF6A1B9A);   // 메인 보라
const Color bnkPrimarySoft = Color(0xFFF3E5F5); // 연보라 배경
const Color bnkGrayText = Color(0xFF6B7280);
const Color bnkCardBg = Colors.white;

class OtpRegisterScreen extends StatefulWidget {
  const OtpRegisterScreen({super.key});

  @override
  State<OtpRegisterScreen> createState() => _OtpRegisterScreenState();
}

class _OtpRegisterScreenState extends State<OtpRegisterScreen> {
  bool phoneVerified = false;
  bool idVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP 등록'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OTP는 이체 및 이체 한도 변경 시 사용하는\n추가 보안 수단입니다.',
              style: TextStyle(fontSize: 14, color: bnkGrayText),
            ),

            const SizedBox(height: 32),

            _stepTile(
              title: '휴대폰 본인인증',
              verified: phoneVerified,
              onTap: () async {
                // TODO: PASS 인증 연동
                setState(() => phoneVerified = true);
              },
            ),

            const SizedBox(height: 12),

            _stepTile(
              title: '신분증 인증',
              verified: idVerified,
              onTap: phoneVerified
                  ? () async {
                // TODO: OCR 인증
                setState(() => idVerified = true);
              }
                  : null,
            ),

            const Spacer(),

            ElevatedButton(
              onPressed: phoneVerified && idVerified
                  ? () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OtpPinRegisterScreen(),
                  ),
                );

                if (result == true && mounted) {
                  Navigator.pop(context, true); // 🔴 SecurityCenter로 결과 전달
                }
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: bnkPrimary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTile({
    required String title,
    required bool verified,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: verified ? bnkPrimary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              verified ? Icons.check_circle : Icons.radio_button_unchecked,
              color: verified ? bnkPrimary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

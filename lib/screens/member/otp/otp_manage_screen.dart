import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tkbank/screens/member/otp/otp_issue_intro_screen.dart';
import 'package:tkbank/screens/member/otp/otp_pin_register_screen.dart';
import 'package:tkbank/screens/member/otp/otp_pin_verify_screen.dart';
import 'package:tkbank/services/otp_pin_storage_service.dart';
const Color bnkPrimary = Color(0xFF6A1B9A);   // 메인 보라
const Color bnkPrimarySoft = Color(0xFFF3E5F5); // 연보라 배경
const Color bnkGrayText = Color(0xFF6B7280);
const Color bnkCardBg = Colors.white;

class OtpManageScreen extends StatelessWidget {
  const OtpManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디지털OTP'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _menuItem(
            context,
            title: '디지털OTP(재)발급',
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const OtpIssueIntroScreen(),
                ),
              );

              // SecurityCenterScreen으로 true 전달
              if (result == true && context.mounted) {
                Navigator.pop(context, true); // ✅ SecurityCenterScreen으로 결과 반환
              }
            },
          ),

          _menuItem(
            context,
            title: '디지털OTP 해지',
            onTap: () async {
              final otpService = OtpPinStorageService();
              final hasPin = await otpService.hasOtpPin();

              if (!hasPin) {
                // OTP PIN이 없으면 안내
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('해지할 OTP가 없습니다.')),
                  );
                }
                return;
              }

              // PIN이 있으면 해지 화면으로 이동
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OtpPinVerifyScreen(),
                ),
              );

              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('디지털 OTP가 해지되었습니다.')),
                );
              }
            },
          ),

          _menuItem(
            context,
            title: 'PIN번호 재등록',
            onTap: () async {
              final otpService = OtpPinStorageService();
              final hasPin = await otpService.hasOtpPin();

              if (!hasPin) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('등록된 OTP가 없습니다.')),
                  );
                }
                return;
              }

              // 1️⃣ 기존 PIN 인증
              final verifyResult = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OtpPinVerifyScreen(),
                ),
              );

              if (verifyResult == true && context.mounted) {
                // 2️⃣ 새 PIN 등록
                final registerResult = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OtpPinRegisterScreen(),
                  ),
                );

                if (registerResult == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN번호가 재등록되었습니다.')),
                  );
                }
              }
            },
          ),

        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context,
      {required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

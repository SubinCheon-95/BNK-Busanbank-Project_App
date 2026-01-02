/*
  날짜: 2025/12/22
  내용: 인증센터 UI 수정
  이름: 오서정
*/
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/screens/member/otp/otp_manage_screen.dart';
import 'package:tkbank/screens/member/otp/otp_register_screen.dart';
import 'package:tkbank/screens/member/pin/pin_register_screen.dart';
import 'package:tkbank/screens/member/transfer_limit_screen.dart';
import 'package:tkbank/services/biometric_auth_service.dart';
import 'package:tkbank/services/biometric_storage_service.dart';
import 'package:tkbank/services/otp_pin_storage_service.dart';
import 'package:tkbank/services/pin_storage_service.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

const Color bnkPrimary = Color(0xFF6A1B9A);   // 메인 보라
const Color bnkPrimarySoft = Color(0xFFF3E5F5); // 연보라 배경
const Color bnkGrayText = Color(0xFF6B7280);
const Color bnkCardBg = Colors.white;

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {

  bool _hasPin = false;
  bool _bioEnabled = false;
  bool _otpRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    final hasPin = await PinStorageService().hasPin();
    final bioEnabled = await BiometricStorageService().isEnabled();
    final otpRegistered = await OtpPinStorageService().hasOtpPin();


    if (!mounted) return;

    setState(() {
      _hasPin = hasPin;
      _bioEnabled = bioEnabled;
      _otpRegistered = otpRegistered;
    });
  }

  void _checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 로그인 상태 확실히 확인
    if (!auth.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bnkPrimarySoft,
      appBar: AppBar(
        title: const Text(
          '인증센터',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _SecurityItem(
              icon: Icons.password,
              title: '간편 비밀번호',
              subtitle: _hasPin ? '● 등록됨 · 변경 / 해제' : '등록하기',
              enabled: _hasPin,
              onTap: () async {
                if (_hasPin) {
                  // 🔹 이미 등록됨 → 해제 물어봄
                  await _confirmRemovePin();
                } else {
                  // 🔹 미등록 → 등록 화면
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PinRegisterScreen()),
                  );

                  if (result == true) {
                    await _loadSecurityStatus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('간편 비밀번호가 등록되었습니다')),
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 16),

            _SecurityItem(
              icon: Icons.fingerprint,
              title: '생체 인증',
              subtitle: _bioEnabled ? '● 활성화됨 · 해제' : '등록하기',
              enabled: _bioEnabled,
              onTap: () async {
                if (_bioEnabled) {
                  await _confirmDisableBiometric();
                  return;
                }

                final bio = BiometricAuthService();
                final store = BiometricStorageService();

                final canUse = await bio.canUseBiometrics();
                if (!canUse) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이 기기에서는 생체 인증을 사용할 수 없습니다')),
                  );
                  return;
                }

                final ok = await bio.authenticate();
                if (ok) {
                  await store.enable();
                  await _loadSecurityStatus();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('생체 인증이 활성화되었습니다')),
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            _SecurityItem(
              icon: Icons.phonelink_lock,
              title: '디지털OTP',
              subtitle: _otpRegistered
                  ? '● 등록됨 · 이체한도 변경 시 사용'
                  : '이체·한도 변경용 보안수단 등록',
              enabled: _otpRegistered,
                onTap: () async {
                  final before = _otpRegistered;

                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OtpManageScreen()),
                  );

                  await _loadSecurityStatus();

                  if (!mounted) return;

                  // ✅ false -> true로 바뀐 순간만
                  if (!before && _otpRegistered) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OTP가 등록되었습니다')),
                    );
                  }
                },

            ),
/*
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: const Text('이체한도 변경'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransferLimitScreen(),
                  ),
                );
              },
            ),
*/
          ],
        ),
      ),
    );


  }



  Future<void> _confirmRemovePin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('간편 비밀번호 해제'),
        content: const Text('간편 비밀번호를 해제하시겠습니까?\n해제 후에는 아이디 로그인이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await PinStorageService().clearPin();
      await _loadSecurityStatus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('간편 비밀번호가 해제되었습니다')),
      );
    }
  }

  Future<void> _confirmDisableBiometric() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('생체 인증 해제'),
        content: const Text('생체 인증을 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await BiometricStorageService().disable();
      await _loadSecurityStatus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생체 인증이 해제되었습니다')),
      );
    }
  }


}
class _SecurityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _SecurityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: bnkCardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled ? bnkPrimarySoft : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: enabled ? bnkPrimary : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: enabled ? bnkPrimary : bnkGrayText,
                      fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );

  }

}





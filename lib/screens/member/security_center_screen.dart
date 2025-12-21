import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';
import 'package:tkbank/screens/member/login_screen.dart';
import 'package:tkbank/screens/member/pin_register_screen.dart';
import 'package:tkbank/services/biometric_auth_service.dart';
import 'package:tkbank/services/biometric_storage_service.dart';
import 'package:tkbank/services/pin_storage_service.dart';

class SecurityCenterScreen extends StatefulWidget {
  const SecurityCenterScreen({super.key});

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {

  bool _hasPin = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    final hasPin = await PinStorageService().hasPin();
    final bioEnabled = await BiometricStorageService().isEnabled();

    if (!mounted) return;

    setState(() {
      _hasPin = hasPin;
      _bioEnabled = bioEnabled;
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
      appBar: AppBar(
        title: const Text('인증센터'),
        backgroundColor: const Color(0xFF455A64),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _SecurityItem(
              icon: Icons.password,
              title: '간편 비밀번호',
              subtitle: _hasPin ? '등록됨 · 변경 / 해제' : '등록하기',
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
              subtitle: _bioEnabled ? '활성화됨 · 해제' : '등록하기',
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
          ],
        ),
      ),
    );


  }

  void _showNotReady(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 기능은 준비 중입니다.'),
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

  const _SecurityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.grey.shade800),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }



}

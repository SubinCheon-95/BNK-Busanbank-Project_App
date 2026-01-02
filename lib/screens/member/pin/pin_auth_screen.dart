/*
  날짜: 2025/12/22
  내용: 로그인 시 pin 입력 화면
  작성자: 오서정
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tkbank/widgets/pin_dots.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/pin_storage_service.dart';
import '../../../widgets/pin_keypad_panel.dart';

class PinAuthScreen extends StatefulWidget {
  const PinAuthScreen({super.key});

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}
const Color bnkPrimary = Color(0xFF6A1B9A);
const Color bnkPrimarySoft = Color(0xFFF3E5F5);
const Color bnkGray = Color(0xFF9CA3AF);
const Color pinPanelColor = bnkPrimary;        // 메인 보라
const Color pinTextColor = Colors.white;
const Color pinSubTextColor = Colors.white70;

class _PinAuthScreenState extends State<PinAuthScreen> {
  String _pin = '';

  String? _error;

  void _onNumber(String num) async {
    if (_pin.length >= 6) return;

    setState(() {
      _pin += num;
      _error = null; // ⭐ 입력 시작 시 에러 제거
    });

    if (_pin.length == 6) {
      final ok = await PinStorageService().verifyPin(_pin);

      if (!ok) {
        HapticFeedback.mediumImpact();
        setState(() {
          _pin = '';
          _error = '간편 비밀번호가 올바르지 않습니다.';
        });
        return;
      }

      final userId = await const FlutterSecureStorage()
          .read(key: 'simple_login_userId');

      if (userId == null) return;

      await context
          .read<AuthProvider>()
          .loginWithSimpleAuth(userId);

      if (!mounted) return;

      Navigator.pop(context, true);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('간편 비밀번호'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                const Text(
                  '간편 비밀번호를\n입력해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '등록된 간편 비밀번호 6자리를 입력하세요.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          PinDots(length: _pin.length),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const Spacer(),

          PinKeypadPanel(
            onNumber: _onNumber,
            onDelete: _onDelete,
          ),
        ],
      )

    );
  }
}

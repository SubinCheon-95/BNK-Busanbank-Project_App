/*
  날짜: 2025/12/XX
  내용: OTP PIN 인증 후 해지
  이름: 오서정
*/

import 'package:flutter/material.dart';
import 'package:tkbank/services/otp_pin_storage_service.dart';
import 'package:tkbank/widgets/pin_dots.dart';
import 'package:tkbank/widgets/pin_keypad_panel.dart';

const Color bnkPrimary = Color(0xFF6A1B9A);

class OtpPinVerifyScreen extends StatefulWidget {
  const OtpPinVerifyScreen({super.key});

  @override
  State<OtpPinVerifyScreen> createState() => _OtpPinVerifyScreenState();
}

class _OtpPinVerifyScreenState extends State<OtpPinVerifyScreen> {
  final _otpPinService = OtpPinStorageService();

  String _currentPin = '';
  String? _error;

  void _onKeyTap(String value) async {
    if (_currentPin.length >= 6) return;

    setState(() {
      _currentPin += value;
      _error = null;
    });

    if (_currentPin.length == 6) {
      final isValid = await _otpPinService.verifyOtpPin(_currentPin);

      if (isValid) {
        await _otpPinService.clearOtpPin();
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _error = '비밀번호가 일치하지 않습니다.';
          _currentPin = '';
        });
      }
    }
  }

  void _onDelete() {
    if (_currentPin.isEmpty) return;
    setState(() {
      _currentPin =
          _currentPin.substring(0, _currentPin.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP 해지'),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),

          const Text(
            'OTP 비밀번호를\n입력해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          PinDots(length: _currentPin.length),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const Spacer(),

          PinKeypadPanel(
            onNumber: _onKeyTap,
            onDelete: _onDelete,
          ),
        ],
      ),
    );
  }
}

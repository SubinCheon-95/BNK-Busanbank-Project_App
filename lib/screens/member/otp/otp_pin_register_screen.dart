/*
  날짜: 2025/12/22
  내용: 간편 비밀번호 등록 UI 수정
  이름: 오서정
*/
import 'package:flutter/material.dart';
import 'package:tkbank/services/otp_pin_storage_service.dart';
import 'package:tkbank/services/pin_storage_service.dart';
import 'package:tkbank/widgets/pin_dots.dart';
import 'package:tkbank/widgets/pin_keypad_panel.dart';

const Color bnkPrimary = Color(0xFF6A1B9A);
const Color bnkPrimarySoft = Color(0xFFF3E5F5);
const Color bnkGray = Color(0xFF9CA3AF);
const Color pinPanelColor = bnkPrimary;        // 메인 보라
const Color pinTextColor = Colors.white;
const Color pinSubTextColor = Colors.white70;


class OtpPinRegisterScreen  extends StatefulWidget {
  const OtpPinRegisterScreen ({super.key});

  @override
  State<OtpPinRegisterScreen > createState() => _OtpPinRegisterScreenState();
}

class _OtpPinRegisterScreenState extends State<OtpPinRegisterScreen > {

  final _otpPinService = OtpPinStorageService();

  String _firstPin = '';
  String _currentPin = '';
  bool _confirmStep = false;
  String? _error;

  void _onKeyTap(String value) async {
    if (_currentPin.length >= 6) return;

    setState(() {
      _currentPin += value;
      _error = null;
    });

    if (_currentPin.length == 6) {
      if (!_confirmStep) {
        // 1차 입력 완료 → 확인 단계
        _firstPin = _currentPin;
        _currentPin = '';
        _confirmStep = true;
      } else {
        // 2차 입력 완료 → 비교
        if (_firstPin == _currentPin) {
          await _otpPinService.saveOtpPin(_currentPin);
          if (mounted) Navigator.pop(context, true);
        } else {
          setState(() {
            _error = '비밀번호가 일치하지 않습니다.';
            _firstPin = '';
            _currentPin = '';
            _confirmStep = false;
          });
        }
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
        title: const Text(
          'OTP 비밀번호 등록',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: bnkPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Text(
                  _confirmStep
                      ? 'OTP 비밀번호를\n한 번 더 입력해주세요'
                      : 'OTP 비밀번호를\n등록해주세요',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _confirmStep
                      ? '앞에서 입력한 비밀번호와 동일해야 합니다.'
                      : '이체·한도 변경 시 사용할 6자리 숫자입니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
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
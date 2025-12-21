import 'package:flutter/material.dart';
import 'package:tkbank/services/pin_storage_service.dart';

class PinRegisterScreen extends StatefulWidget {
  const PinRegisterScreen({super.key});

  @override
  State<PinRegisterScreen> createState() => _PinRegisterScreenState();
}

class _PinRegisterScreenState extends State<PinRegisterScreen> {
  final _pinService = PinStorageService();

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
          await _pinService.savePin(_currentPin);
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
        title: const Text('간편 비밀번호 등록'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          Text(
            _confirmStep
                ? '간편 비밀번호를 다시 입력하세요'
                : '간편 비밀번호 6자리를 입력하세요',
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 24),

          _PinDots(length: _currentPin.length),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const Spacer(),

          _PinKeyPad(
            onTap: _onKeyTap,
            onDelete: _onDelete,
          ),
        ],
      ),
    );
  }
}
class _PinDots extends StatelessWidget {
  final int length;
  const _PinDots({required this.length});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < length ? Colors.black : Colors.grey.shade300,
          ),
        );
      }),
    );
  }
}
class _PinKeyPad extends StatelessWidget {
  final Function(String) onTap;
  final VoidCallback onDelete;

  const _PinKeyPad({
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1','2','3',
      '4','5','6',
      '7','8','9',
      '','0','←'
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) {
          final key = keys[i];
          if (key == '') return const SizedBox();
          return ElevatedButton(
            onPressed: () {
              if (key == '←') {
                onDelete();
              } else {
                onTap(key);
              }
            },
            child: Text(
              key,
              style: const TextStyle(fontSize: 22),
            ),
          );
        },
      ),
    );
  }
}

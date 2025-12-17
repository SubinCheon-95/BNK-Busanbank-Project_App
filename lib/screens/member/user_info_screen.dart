import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/screens/member/account_setup_screen.dart';
import 'package:tkbank/widgets/register_step_indicator.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final rrnFrontController = TextEditingController();
  final rrnBackController = TextEditingController();
  final addr1Controller = TextEditingController();
  final addr2Controller = TextEditingController();

  /// 🔹 PhoneVerifyScreen 과 동일한 InputBox
  Widget _inputBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  bool isValidJumin(String front, String back) {
    if (!RegExp(r'^\d{6}$').hasMatch(front)) return false;
    if (!RegExp(r'^\d{7}$').hasMatch(back)) return false;

    final nums = (front + back).split('').map(int.parse).toList();
    final multipliers = [2,3,4,5,6,7,8,9,2,3,4,5];

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += nums[i] * multipliers[i];
    }

    final check = (11 - (sum % 11)) % 10;
    return check == nums[12];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// ✅ 하단 고정 버튼 (PhoneVerifyScreen과 동일)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              final rrnFront = rrnFrontController.text.trim();
              final rrnBack = rrnBackController.text.trim();

              if (!isValidJumin(rrnFront, rrnBack)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('유효하지 않은 주민등록번호입니다')),
                );
                return;
              }

              if (addr1Controller.text.trim().isEmpty ||
                  addr2Controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('주소를 모두 입력해주세요')),
                );
                return;
              }

              final rrn = rrnFront + rrnBack;

              context.read<RegisterProvider>().setUserInfo(
                rrn: rrn,
                addr1: addr1Controller.text.trim(),
                addr2: addr2Controller.text.trim(),
              );

              Navigator.pushNamed(context, '/register/account');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '다음',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔙 뒤로가기
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              RegisterStepIndicator(step: 3),
              const SizedBox(height: 32),

              const Text(
                '개인정보 입력',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),

              /// ✅ 주민번호
              _inputBox(
                child: Row(
                  children: [

                    Expanded(
                      child: TextField(
                        controller: rrnFrontController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '주민번호 앞자리',
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: rrnBackController,
                        keyboardType: TextInputType.number,
                        maxLength: 7,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: '뒷자리',
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// ✅ 주소
              _inputBox(
                child: TextField(
                  controller: addr1Controller,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '주소',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _inputBox(
                child: TextField(
                  controller: addr2Controller,
                  decoration: const InputDecoration(
                    labelText: '상세주소',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AccountSetupScreen()),
                  );
                },
                child: const Text('다음 (개발용)'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/services/member_service.dart';
import 'package:tkbank/widgets/register_step_indicator.dart';

class AccountSetupScreen extends StatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  State<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends State<AccountSetupScreen> {
  final idController = TextEditingController();
  final pwController = TextEditingController();
  final accountPwController = TextEditingController();
  final emailController = TextEditingController();

  /// 🔹 앞 단계들과 동일한 InputBox
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

  @override
  void dispose() {
    idController.dispose();
    pwController.dispose();
    accountPwController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RegisterProvider>();

    return Scaffold(
      backgroundColor: Colors.white,

      /// ✅ 하단 고정 버튼 (앞 단계와 동일)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              provider.setAccountInfo(
                userId: idController.text.trim(),
                userPw: pwController.text.trim(),
                accountPassword: accountPwController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
              );

              try {
                await MemberService().register(provider.toJson());
                provider.clear();

                Navigator.pushReplacementNamed(
                  context,
                  '/register/finish',
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '회원가입 완료',
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


              RegisterStepIndicator(step: 4),
              const SizedBox(height: 32),

              const Text(
                '계정 설정',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 40),

              /// ✅ 아이디
              _inputBox(
                child: TextField(
                  controller: idController,
                  decoration: const InputDecoration(
                    labelText: '아이디',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ✅ 비밀번호
              _inputBox(
                child: TextField(
                  controller: pwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ✅ 계좌 비밀번호
              _inputBox(
                child: TextField(
                  controller: accountPwController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '계좌 비밀번호 (숫자 4자리)',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ✅ 이메일 (선택)
              _inputBox(
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일 (선택)',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

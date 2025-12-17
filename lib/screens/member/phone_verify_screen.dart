import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/register_provider.dart';
import 'package:tkbank/screens/member/user_info_screen.dart';
import 'package:tkbank/utils/formatters/phone_number_formatter.dart';
import 'package:tkbank/widgets/register_step_indicator.dart';

class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  final nameController = TextEditingController();
  final hpController = TextEditingController();
  final codeController = TextEditingController();

  bool codeSent = false;

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
  Widget build(BuildContext context) {
    final provider = context.read<RegisterProvider>();

    return Scaffold(
      backgroundColor: Colors.white,

      /// ✅ 하단 고정 버튼 (토스 핵심)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () async {
              try {
                if (!codeSent) {
                  final msg = await provider.sendHpCode(
                    hp: hpController.text,
                  );

                  setState(() => codeSent = true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  final ok = await provider.verifyHpCode(
                    hp: provider.hp ?? hpController.text,
                    code: codeController.text,
                  );

                  if (!ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('인증번호가 올바르지 않습니다'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  provider.setPhoneInfo(
                    hp: hpController.text,
                    userName: nameController.text,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserInfoScreen()),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceAll('Exception: ', ''),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              codeSent ? '인증 완료' : '인증번호 받기',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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

              RegisterStepIndicator(step: 2),
              const SizedBox(height: 32),

              /// ✅ 타이틀 영역
              const Text(
                '휴대폰 본인 인증',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '본인 명의의 휴대폰 번호를 입력해주세요',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),

              /// ✅ 이름 입력
              _inputBox(
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ✅ 휴대폰 번호 입력
              _inputBox(
                child: TextField(
                  controller: hpController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(13),
                    PhoneNumberFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: '휴대폰 번호',
                    hintText: '010-1234-5678',
                    border: InputBorder.none,
                  ),
                ),
              ),

              /// ✅ 인증번호 입력 (부드럽게 등장)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: codeSent
                    ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _inputBox(
                    child: TextField(
                      controller: codeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '인증번호',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserInfoScreen()),
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

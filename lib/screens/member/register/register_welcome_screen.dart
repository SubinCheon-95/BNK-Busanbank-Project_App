import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:tkbank/screens/member/login_screen.dart';

class RegisterWelcomeScreen extends StatefulWidget {
  const RegisterWelcomeScreen({super.key});

  @override
  State<RegisterWelcomeScreen> createState() => _RegisterWelcomeScreenState();
}

class _RegisterWelcomeScreenState extends State<RegisterWelcomeScreen> {

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Lottie.asset('assets/lottie/Success.json'),
              ),

              const SizedBox(height: 24),

              const Text(
                '환영합니다.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                '딸깍은행 회원가입이\n완료되었습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// 2025/12/18 - 정보 수정 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/member_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final MemberService _memberService = MemberService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _addr1Controller = TextEditingController();
  final TextEditingController _addr2Controller = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _hpController.dispose();
    _zipController.dispose();
    _addr1Controller.dispose();
    _addr2Controller.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('로그인 필요');
      }

      await _memberService.updateUserInfo(
        userId: userId,
        email: _emailController.text.trim(),
        hp: _hpController.text.replaceAll('-', ''),
        zip: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
        addr1: _addr1Controller.text.trim().isEmpty ? null : _addr1Controller.text.trim(),
        addr2: _addr2Controller.text.trim().isEmpty ? null : _addr2Controller.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정보가 수정되었습니다')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보 수정 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정보 수정'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력하세요';
                }
                if (!value.contains('@')) {
                  return '올바른 이메일 형식이 아닙니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hpController,
              decoration: const InputDecoration(
                labelText: '휴대폰 번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '01012345678',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '휴대폰 번호를 입력하세요';
                }
                final cleaned = value.replaceAll('-', '');
                if (cleaned.length != 11) {
                  return '올바른 휴대폰 번호가 아닙니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '주소 정보 (선택사항)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipController,
              decoration: const InputDecoration(
                labelText: '우편번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addr1Controller,
              decoration: const InputDecoration(
                labelText: '기본주소',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addr2Controller,
              decoration: const InputDecoration(
                labelText: '상세주소',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_work),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('저장', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

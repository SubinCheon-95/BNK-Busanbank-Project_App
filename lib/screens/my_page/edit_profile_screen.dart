// 2025/12/18 - 정보 수정 화면 - 작성자: 진원
// 2025/12/29 - 다음 주소 검색 API 연동 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kpostal/kpostal.dart';
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
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인 필요');
      }

      final profile = await _memberService.getUserProfile(userNo);

      // 기존 정보로 입력 필드 채우기
      _emailController.text = profile.email ?? '';
      _hpController.text = profile.hp ?? '';
      _zipController.text = profile.zip ?? '';
      _addr1Controller.text = profile.addr1 ?? '';
      _addr2Controller.text = profile.addr2 ?? '';

      setState(() => _isLoadingData = false);
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('정보 조회 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _hpController.dispose();
    _zipController.dispose();
    _addr1Controller.dispose();
    _addr2Controller.dispose();
    super.dispose();
  }

  /// 다음 주소 검색 (2025/12/29 - 작성자: 진원)
  Future<void> _searchAddress() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KpostalView(
            useLocalServer: true,
            localPort: 8080,
            // 주소 선택 완료 콜백
            callback: (Kpostal result) {
              setState(() {
                _zipController.text = result.postCode;
                _addr1Controller.text = result.address;
                // 상세주소 입력 필드로 포커스 이동
                FocusScope.of(context).requestFocus(FocusNode());
              });
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주소 검색 실패: $e')),
        );
      }
    }
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
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _zipController,
                    decoration: const InputDecoration(
                      labelText: '우편번호',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _searchAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('주소 검색'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addr1Controller,
              decoration: const InputDecoration(
                labelText: '기본주소',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              readOnly: true,
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

// 2025/12/18 - 회원 탈퇴 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/member_service.dart';

class WithdrawAccountScreen extends StatefulWidget {
  const WithdrawAccountScreen({super.key});

  @override
  State<WithdrawAccountScreen> createState() => _WithdrawAccountScreenState();
}

class _WithdrawAccountScreenState extends State<WithdrawAccountScreen> {
  final MemberService _memberService = MemberService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agree = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _withdraw() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원 탈퇴 안내를 확인하고 동의해주세요')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말로 탈퇴하시겠습니까?\n'
          '탈퇴 후 7일 동안 재가입이 불가능합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('로그인 필요');
      }

      await _memberService.withdrawAccount(
        userId: userId,
        password: _passwordController.text,
      );

      // 로그아웃 처리
      await authProvider.logout();

      if (mounted) {
        // 로그인 화면으로 이동
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원 탈퇴가 완료되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원 탈퇴 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 탈퇴'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWarningBox(),
            const SizedBox(height: 24),
            _buildNoticeBox(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력하세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _agree,
              onChanged: (value) => setState(() => _agree = value ?? false),
              title: const Text('위 내용을 모두 확인하였으며, 회원 탈퇴에 동의합니다.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _withdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('회원 탈퇴', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                '회원 탈퇴 주의사항',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '회원 탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '탈퇴 시 삭제되는 정보',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text('• 회원 정보 (이메일, 전화번호 등)'),
          Text('• 보유 포인트 및 쿠폰'),
          Text('• 가입한 금융상품 정보'),
          Text('• 활동 이력'),
          SizedBox(height: 16),
          Text(
            '기타 안내',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text('• 탈퇴 후 7일간 재가입이 불가능합니다'),
          Text('• 진행 중인 금융상품은 해지 후 탈퇴해주세요'),
        ],
      ),
    );
  }
}

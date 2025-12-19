// 2025/12/18 - 설정 메뉴 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'withdraw_account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('사용자 정보'),
          _buildMenuItem(
            context,
            icon: Icons.edit,
            title: '정보 수정',
            subtitle: '이메일, 전화번호, 주소 변경',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.lock,
            title: '비밀번호 변경',
            subtitle: '새로운 비밀번호로 변경',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
            ),
          ),
          const Divider(),
          _buildSectionHeader('계정 관리'),
          _buildMenuItem(
            context,
            icon: Icons.exit_to_app,
            title: '회원 탈퇴',
            subtitle: '계정을 영구적으로 삭제',
            textColor: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WithdrawAccountScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? const Color(0xFF2196F3)),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

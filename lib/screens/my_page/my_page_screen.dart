// 2025/12/18 - 마이페이지 메인 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/member_service.dart';
import '../../services/point_service.dart';
import '../../models/user_profile.dart';
import '../../models/point.dart';
import 'profile_screen.dart';
import 'coupon_list_screen.dart';
import 'my_products_screen.dart';
import 'settings_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final MemberService _memberService = MemberService();
  final PointService _pointService = PointService();

  UserProfile? _userProfile;
  Point? _point;
  bool _isLoading = true;

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
      final point = await _pointService.getUserPoints(userNo);

      setState(() {
        _userProfile = profile;
        _point = point;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 조회 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 16),
                    _buildMenuSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF2196F3),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 50, color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.userId ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?.email ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('보유 포인트', '${_point?.availablePoints ?? 0}P'),
              _buildStatItem('가입 상품', '${_userProfile?.countUserItems ?? 0}개'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.person_outline,
          title: '프로필',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
        ),
        _buildMenuItem(
          icon: Icons.card_giftcard,
          title: '쿠폰함',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CouponListScreen()),
          ),
        ),
        _buildMenuItem(
          icon: Icons.account_balance_wallet,
          title: '나의 금융상품',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyProductsScreen()),
          ),
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: '설정',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2196F3)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

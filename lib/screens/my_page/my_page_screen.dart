// 2025/12/18 - 마이페이지 메인 화면 - 작성자: 진원
// 2025/12/23 - 프로필 수정 기능 추가 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/member_service.dart';
import '../../services/point_service.dart';
import '../../models/user_profile.dart';
import '../../models/point.dart';
import 'profile_screen.dart';
import 'profile_edit_screen.dart';
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

  // 2025/12/19 - BuildContext 사용 문제 수정 및 에러 처리 개선 - 작성자: 진원
  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인 필요');
      }

      print('[DEBUG] 마이페이지 - userNo: $userNo'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원

      final profile = await _memberService.getUserProfile(userNo);
      print('[DEBUG] 프로필 조회 성공: ${profile.userId}'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원

      final point = await _pointService.getUserPoints(userNo);
      print('[DEBUG] 포인트 조회 성공: ${point.availablePoints}P'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _point = point;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[ERROR] 마이페이지 데이터 조회 실패: $e'); // 2025/12/19 - 디버그 로그 추가 - 작성자: 진원
      if (mounted) {
        setState(() => _isLoading = false);
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final nickname = authProvider.nickname;
    final avatarImage = authProvider.avatarImage;

    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF2196F3),
      child: Column(
        children: [
          // 아바타 이미지 (프로필 수정 버튼 포함)
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: avatarImage != null
                    ? NetworkImage(avatarImage)
                    : null,
                child: avatarImage == null
                    ? const Icon(Icons.person, size: 50, color: Color(0xFF2196F3))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    // 프로필 수정 화면으로 이동
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileEditScreen(),
                      ),
                    );
                    // 프로필이 업데이트되면 데이터 새로고침
                    if (result == true) {
                      _loadUserData();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2196F3), width: 2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 닉네임 또는 사용자 ID 표시
          Text(
            nickname ?? _userProfile?.userId ?? '',
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

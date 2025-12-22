// 2025/12/18 - 프로필 상세 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/member_service.dart';
import '../../services/point_service.dart';
import '../../models/user_profile.dart';
import '../../models/point.dart';
import '../member/point_history_screen.dart';
import '../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
        title: const Text('프로필'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildInfoSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF2196F3),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 60, color: Color(0xFF2196F3)),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.userId ?? '',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('기본 정보', [
            _buildInfoRow('로그인 ID', _userProfile?.userId ?? ''),
            _buildInfoRow('이메일', _userProfile?.email ?? ''),
            _buildInfoRow('전화번호', _userProfile?.hp ?? ''),
            _buildInfoRow('최근 접속', _userProfile?.lastConnectTime ?? ''),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(
            '포인트 정보',
            [
              _buildInfoRow('총 포인트', '${_point?.totalPoints ?? 0}P'),
              _buildInfoRow('사용 가능 포인트', '${_point?.availablePoints ?? 0}P'),
              _buildInfoRow('사용한 포인트', '${_point?.usedPoints ?? 0}P'),
            ],
            actionLabel: '상세보기',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PointHistoryScreen(baseUrl: MyApp.baseUrl),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildInfoCard('주소 정보', [
            _buildInfoRow('우편번호', _userProfile?.zip ?? '-'),
            _buildInfoRow('기본주소', _userProfile?.addr1 ?? '-'),
            _buildInfoRow('상세주소', _userProfile?.addr2 ?? '-'),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    List<Widget> children, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: Text(actionLabel),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

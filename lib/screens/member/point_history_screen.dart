// 2025/12/16 - 포인트 이력 조회 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/flutter_api_service.dart';

class PointHistoryScreen extends StatefulWidget {
  final String baseUrl;

  const PointHistoryScreen({super.key, required this.baseUrl});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  late FlutterApiService _apiService;
  int _totalPoints = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // 임시 포인트 이력 데이터 (백엔드 API 구현 전)
  final List<Map<String, dynamic>> _mockHistory = [
    {
      'pointId': 1,
      'pointAmount': 100,
      'pointType': 'EARN',
      'description': '회원가입 보너스',
      'createdAt': DateTime.now().subtract(const Duration(days: 7)),
    },
    {
      'pointId': 2,
      'pointAmount': 50,
      'pointType': 'EARN',
      'description': '상품 가입',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'pointId': 3,
      'pointAmount': 30,
      'pointType': 'USE',
      'description': '포인트 사용',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'pointId': 4,
      'pointAmount': 200,
      'pointType': 'EARN',
      'description': '이벤트 참여',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2025/12/16 - 로그인한 사용자 번호 사용 - 작성자: 진원
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null || userNo.isEmpty) {
        setState(() {
          _errorMessage = '로그인이 필요합니다';
          _isLoading = false;
        });
        return;
      }

      final pointData = await _apiService.getUserPoints(int.parse(userNo));
      setState(() {
        _totalPoints = pointData['totalPoints'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '포인트 조회에 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 이력'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPoints,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPoints,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPoints,
      child: Column(
        children: [
          _buildPointSummaryCard(),
          const Divider(height: 1),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPointSummaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '보유 포인트',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_totalPoints.toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (Match m) => '${m[1]},',
                )} P',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.white70),
                SizedBox(width: 8),
                Text(
                  '포인트는 상품 가입 시 사용 가능합니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_mockHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('포인트 이력이 없습니다'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _mockHistory.length,
      itemBuilder: (context, index) {
        final history = _mockHistory[index];
        return _buildHistoryItem(history);
      },
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> history) {
    final isEarn = history['pointType'] == 'EARN';
    final amount = history['pointAmount'] as int;
    final description = history['description'] as String;
    final date = history['createdAt'] as DateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEarn
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isEarn ? Icons.add_circle : Icons.remove_circle,
                color: isEarn ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isEarn ? '+' : '-'}$amount P',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isEarn ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

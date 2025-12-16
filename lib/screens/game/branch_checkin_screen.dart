import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:tkbank/providers/auth_provider.dart';

// 2025-12-16 - 영업점 체크인 화면 (API 연동) - 작성자: 진원
class BranchCheckinScreen extends StatefulWidget {
  final String baseUrl;

  const BranchCheckinScreen({super.key, required this.baseUrl});

  @override
  State<BranchCheckinScreen> createState() => _BranchCheckinScreenState();
}

class _BranchCheckinScreenState extends State<BranchCheckinScreen> {
  bool isLoading = false;
  int totalCheckins = 0;
  int earnedPoints = 0;
  String? lastCheckinBranch;
  String? lastCheckinDate;

  List<Map<String, dynamic>> branches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCheckinHistory(),
      _loadBranches(),
    ]);
  }

  Future<void> _loadCheckinHistory() async {
    try {
      // 로그인한 사용자 정보 가져오기
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인이 필요합니다');
      }

      final response = await http.get(
        Uri.parse('${widget.baseUrl}/flutter/checkin/history/$userNo'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalCheckins = data['totalCheckins'] ?? 0;
          earnedPoints = data['earnedPoints'] ?? 0;

          if (data['lastCheckin'] != null) {
            lastCheckinBranch = data['lastCheckin']['branchName'];
            lastCheckinDate = data['lastCheckin']['checkinDate'];
          }
        });
      }
    } catch (e) {
      debugPrint('체크인 기록 로드 실패: $e');
    }
  }

  Future<void> _loadBranches() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/flutter/branches'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          branches = data.map((branch) {
            // 거리는 임시로 랜덤 생성 (실제로는 GPS 위치 기반 계산)
            double distance = (branch['branchId'] % 10) * 0.5 + 0.3;
            bool isNearby = distance < 1.0;

            return {
              'id': branch['branchId'],
              'name': branch['branchName'] ?? '',
              'address': branch['branchAddr'] ?? '',
              'distance': distance,
              'isNearby': isNearby,
            };
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('지점 목록 조회 실패');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  Future<void> _checkin(Map<String, dynamic> branch) async {
    if (!branch['isNearby']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('영업점 근처에서만 체크인할 수 있습니다 (반경 1km 이내)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${branch['name']} 체크인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${branch['name']}에 체크인하시겠습니까?'),
            const SizedBox(height: 8),
            const Text(
              '20 포인트를 받을 수 있어요!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('체크인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      // 로그인한 사용자 정보 가져오기
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인이 필요합니다');
      }

      final response = await http.post(
        Uri.parse('${widget.baseUrl}/flutter/checkin'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userNo,
          'branchId': branch['id'],
          'latitude': 35.1234, // 임시 위도 (실제로는 GPS에서 가져옴)
          'longitude': 129.1234, // 임시 경도
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // 체크인 성공 - 데이터 새로고침
          await _loadCheckinHistory();

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('체크인 완료!'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF2196F3),
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['branchName'] ?? branch['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data['earnedPoints']} 포인트 적립!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          }
        } else {
          // 실패 메시지 표시
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? '체크인 실패')),
            );
          }
        }
      } else {
        throw Exception('체크인 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('체크인 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영업점 체크인'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 체크인 현황 카드
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '나의 체크인 현황',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            icon: Icons.location_on,
                            label: '총 체크인',
                            value: '$totalCheckins회',
                          ),
                          _buildStatColumn(
                            icon: Icons.stars,
                            label: '획득 포인트',
                            value: '$earnedPoints P',
                          ),
                        ],
                      ),
                      if (lastCheckinBranch != null) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white30),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '최근: $lastCheckinBranch',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // 지점 목록
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: branches.length,
                    itemBuilder: (context, index) {
                      final branch = branches[index];
                      final isNearby = branch['isNearby'] as bool;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isNearby
                                  ? const Color(0xFF2196F3).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: isNearby ? const Color(0xFF2196F3) : Colors.grey,
                              size: 28,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  branch['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isNearby)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '근처',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                branch['address'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_walk,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${branch['distance'].toStringAsFixed(1)}km',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: isNearby ? () => _checkin(branch) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('체크인'),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 안내 메시지
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '체크인 안내',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('• 영업점 반경 1km 이내에서 체크인 가능'),
                      Text('• 체크인 시 20 포인트 적립'),
                      Text('• 하루에 한 번만 체크인 가능'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

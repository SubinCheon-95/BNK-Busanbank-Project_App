// 2025/12/16 - 쿠폰 조회 및 등록 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_coupon.dart';
import '../../providers/auth_provider.dart';
import '../../services/flutter_api_service.dart';

class CouponScreen extends StatefulWidget {
  final String baseUrl;

  const CouponScreen({super.key, required this.baseUrl});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  late FlutterApiService _apiService;
  List<UserCoupon> _coupons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = FlutterApiService(baseUrl: widget.baseUrl);
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
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

      final coupons = await _apiService.getCoupons(int.parse(userNo));
      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '쿠폰 조회에 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _showRegisterCouponDialog() {
    final TextEditingController couponCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('쿠폰 등록'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('쿠폰 코드를 입력하세요'),
            const SizedBox(height: 16),
            TextField(
              controller: couponCodeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '쿠폰 코드',
                hintText: 'XXXXX',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = couponCodeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('쿠폰 코드를 입력하세요')),
                );
                return;
              }

              // TODO: 실제 쿠폰 등록 API 호출
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('쿠폰 등록: $code (개발 중)')),
              );
            },
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 쿠폰'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCoupons,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterCouponDialog,
        icon: const Icon(Icons.add),
        label: const Text('쿠폰 등록'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
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
              onPressed: _loadCoupons,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('보유한 쿠폰이 없습니다'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showRegisterCouponDialog,
              icon: const Icon(Icons.add),
              label: const Text('쿠폰 등록하기'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCoupons,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _coupons.length,
        itemBuilder: (context, index) {
          final coupon = _coupons[index];
          return _buildCouponCard(coupon);
        },
      ),
    );
  }

  Widget _buildCouponCard(UserCoupon coupon) {
    final isExpired = coupon.expiryDate != null &&
        coupon.expiryDate!.isBefore(DateTime.now());
    final isUsed = coupon.isUsed;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isUsed || isExpired
              ? const LinearGradient(
                  colors: [Colors.grey, Colors.grey],
                )
              : const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      coupon.couponName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isUsed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '사용완료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isExpired && !isUsed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '기간만료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '금리 +${(coupon.bonusRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (coupon.expiryDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      '유효기간: ${_formatDate(coupon.expiryDate!)}까지',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

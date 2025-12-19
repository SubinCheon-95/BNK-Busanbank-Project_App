// 2025/12/18 - 쿠폰함 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/coupon_service.dart';
import '../../models/coupon.dart';

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  final CouponService _couponService = CouponService();
  final TextEditingController _couponCodeController = TextEditingController();

  List<Coupon> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userNo = authProvider.userNo;

      if (userNo == null) {
        throw Exception('로그인 필요');
      }

      final coupons = await _couponService.getUserCoupons(userNo);

      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('쿠폰 조회 실패: $e')),
        );
      }
    }
  }

  Future<void> _registerCoupon() async {
    final code = _couponCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('쿠폰 코드를 입력하세요')),
      );
      return;
    }

    try {
      final result = await _couponService.registerCoupon(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '쿠폰이 등록되었습니다')),
        );
        _couponCodeController.clear();
        _loadCoupons(); // 목록 새로고침
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableCoupons = _coupons.where((c) => c.isAvailable).toList();
    final usedCoupons = _coupons.where((c) => c.isUsed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('쿠폰함'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildRegisterSection(),
                _buildStats(availableCoupons.length, usedCoupons.length),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Color(0xFF2196F3),
                          tabs: [
                            Tab(text: '사용 가능'),
                            Tab(text: '사용 완료'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildCouponList(availableCoupons),
                              _buildCouponList(usedCoupons),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRegisterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _couponCodeController,
              decoration: const InputDecoration(
                hintText: '쿠폰 코드 입력',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _registerCoupon,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int available, int used) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('사용 가능', available, Colors.green),
          _buildStatItem('사용 완료', used, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildCouponList(List<Coupon> coupons) {
    if (coupons.isEmpty) {
      return const Center(child: Text('쿠폰이 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return _buildCouponCard(coupon);
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  coupon.couponName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: coupon.isAvailable ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    coupon.isAvailable ? '사용 가능' : '사용 완료',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('코드: ${coupon.couponCode}'),
            Text('금리 인상: +${coupon.rateIncrease}%'),
            if (coupon.productName != null)
              Text('적용 상품: ${coupon.productName}'),
            const SizedBox(height: 8),
            Text(
              '유효기간: ${coupon.issuedDate} ~ ${coupon.validTo}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

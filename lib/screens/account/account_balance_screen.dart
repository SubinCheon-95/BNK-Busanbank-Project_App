// 2025/12/29 - 계좌 잔액 조회 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import '../../services/account_service.dart';
import 'package:intl/intl.dart';

class AccountBalanceScreen extends StatefulWidget {
  final String accountNo;

  const AccountBalanceScreen({super.key, required this.accountNo});

  @override
  State<AccountBalanceScreen> createState() => _AccountBalanceScreenState();
}

class _AccountBalanceScreenState extends State<AccountBalanceScreen> {
  final AccountService _accountService = AccountService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');

  int? _balance;
  bool _isLoading = true;
  bool _showBalance = true; // 잔액 숨김/표시 토글

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      setState(() => _isLoading = true);

      final result = await _accountService.getBalance(widget.accountNo);

      if (mounted) {
        setState(() {
          _balance = result['balance'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('잔액 조회 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('계좌 잔액'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showBalance ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _showBalance = !_showBalance);
            },
            tooltip: _showBalance ? '잔액 숨기기' : '잔액 표시',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBalance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 계좌번호 카드
                      _buildAccountCard(),
                      const SizedBox(height: 24),

                      // 잔액 표시 카드
                      _buildBalanceCard(),
                      const SizedBox(height: 24),

                      // 안내 메시지
                      _buildInfoSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: const Color(0xFF2196F3), size: 28),
                const SizedBox(width: 12),
                const Text(
                  'TK Bank 입출금 통장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.accountNo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2196F3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 잔액',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showBalance
                  ? '${_currencyFormat.format(_balance ?? 0)}원'
                  : '●●●●●●원',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '안내사항',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 표시된 잔액은 실시간 잔액입니다.\n'
            '• 화면을 아래로 당기면 새로고침됩니다.\n'
            '• 우측 상단 아이콘으로 잔액을 숨길 수 있습니다.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

// 2025/12/29 - 거래내역 조회 화면 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/account_service.dart';
import '../../models/transaction.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String? accountNo; // null이면 전체 거래내역 조회

  const TransactionHistoryScreen({super.key, this.accountNo});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final AccountService _accountService = AccountService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() => _isLoading = true);

      List<Transaction> transactions;

      if (widget.accountNo != null) {
        // 계좌별 조회
        transactions =
            await _accountService.getTransactionHistoryByAccount(widget.accountNo!);
      } else {
        // 사용자별 전체 조회
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.userNo;

        if (userId == null) {
          throw Exception('로그인이 필요합니다');
        }

        transactions = await _accountService.getTransactionHistoryByUser(userId);
      }

      if (mounted) {
        setState(() {
          // transactionId 기준으로 중복 제거
          final seen = <int>{};
          _transactions = transactions.where((transaction) {
            if (seen.contains(transaction.transactionId)) {
              return false;
            }
            seen.add(transaction.transactionId);
            return true;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거래내역 조회 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountNo != null ? '계좌 거래내역' : '전체 거래내역'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '거래내역이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    // 계좌번호가 지정된 경우 입금/출금 판단
    final bool isDeposit = widget.accountNo != null
        ? transaction.isDeposit(widget.accountNo!)
        : transaction.toAccountNo.isNotEmpty;

    final Color amountColor = isDeposit ? Colors.blue : Colors.red;
    final String amountSign = isDeposit ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTransactionDetail(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 거래 타입
                  Row(
                    children: [
                      Icon(
                        isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                        color: amountColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDeposit ? '입금' : '출금',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  // 거래 금액
                  Text(
                    '$amountSign${_currencyFormat.format(transaction.amount)}원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 상대 계좌
              Row(
                children: [
                  Icon(Icons.account_balance_wallet,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isDeposit
                          ? '${transaction.fromAccountNo}에서'
                          : '${transaction.toAccountNo}로',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 거래 후 잔액
              Row(
                children: [
                  Icon(Icons.account_balance,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '잔액: ${_currencyFormat.format(transaction.balanceAfter)}원',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              if (transaction.description != null &&
                  transaction.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              // 거래 일시
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(transaction.transactionDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(Transaction transaction) {
    final bool isDeposit = widget.accountNo != null
        ? transaction.isDeposit(widget.accountNo!)
        : transaction.toAccountNo.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDeposit ? Colors.blue : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(isDeposit ? '입금 내역' : '출금 내역'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('거래번호', transaction.transactionId.toString()),
            const Divider(),
            _buildDetailRow('출금 계좌', transaction.fromAccountNo),
            _buildDetailRow('입금 계좌', transaction.toAccountNo),
            const Divider(),
            _buildDetailRow(
                '거래 금액', '${_currencyFormat.format(transaction.amount)}원'),
            _buildDetailRow('거래 후 잔액',
                '${_currencyFormat.format(transaction.balanceAfter)}원'),
            const Divider(),
            if (transaction.description != null &&
                transaction.description!.isNotEmpty)
              _buildDetailRow('메모', transaction.description!),
            _buildDetailRow('거래 일시', _formatDate(transaction.transactionDate)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      // "2025-12-29 14:30:15" 형식 파싱
      final date = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      return _dateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

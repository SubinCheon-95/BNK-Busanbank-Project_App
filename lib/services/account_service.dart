// 2025/12/29 - 계좌 관련 API 서비스 - 작성자: 진원
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import 'token_storage_service.dart';

class AccountService {
  final TokenStorageService _tokenStorage = TokenStorageService();

  // JWT 헤더 생성
  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenStorage.readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 사용자 계좌 목록 조회
  Future<List<Account>> getUserAccounts(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/transaction/accounts/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> accounts = data['accounts'] ?? [];
          return accounts.map((json) => Account.fromJson(json)).toList();
        } else {
          throw Exception('계좌 목록 조회 실패');
        }
      } else {
        throw Exception('계좌 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('계좌 목록 조회 중 오류 발생: $e');
    }
  }
  // 계좌 잔액 조회
  Future<Map<String, dynamic>> getBalance(String accountNo) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/transaction/balance/$accountNo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('잔액 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('잔액 조회 중 오류 발생: $e');
    }
  }

  // 계좌 이체
  Future<Map<String, dynamic>> transferMoney({
    required int userId,
    required String fromAccountNo,
    required String toAccountNo,
    required int amount,
    String? description,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/transaction/transfer'),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'fromAccountNo': fromAccountNo,
          'toAccountNo': toAccountNo,
          'amount': amount,
          'description': description ?? '계좌이체',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? '이체 실패');
      }
    } catch (e) {
      throw Exception('이체 중 오류 발생: $e');
    }
  }

  // 사용자별 거래내역 조회
  Future<List<Transaction>> getTransactionHistoryByUser(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/transaction/history/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> transactions = data['transactions'] ?? [];
          return transactions
              .map((json) => Transaction.fromJson(json))
              .toList();
        } else {
          throw Exception('거래내역 조회 실패');
        }
      } else {
        throw Exception('거래내역 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('거래내역 조회 중 오류 발생: $e');
    }
  }

  // 계좌별 거래내역 조회
  Future<List<Transaction>> getTransactionHistoryByAccount(
      String accountNo) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/transaction/account/$accountNo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> transactions = data['transactions'] ?? [];
          return transactions
              .map((json) => Transaction.fromJson(json))
              .toList();
        } else {
          throw Exception('거래내역 조회 실패');
        }
      } else {
        throw Exception('거래내역 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('거래내역 조회 중 오류 발생: $e');
    }
  }

  // 거래내역 상세 조회
  Future<Transaction> getTransactionDetail(int transactionId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/transaction/detail/$transactionId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Transaction.fromJson(data['transaction']);
        } else {
          throw Exception('거래 상세 조회 실패');
        }
      } else {
        throw Exception('거래 상세 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('거래 상세 조회 중 오류 발생: $e');
    }
  }
}

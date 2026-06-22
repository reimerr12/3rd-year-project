import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class BkashTokenResult {
  final String idToken;
  final String refreshToken;
  const BkashTokenResult({required this.idToken, required this.refreshToken});
}

class BkashPaymentResult {
  final String paymentId;
  final String bkashUrl;
  const BkashPaymentResult({required this.paymentId, required this.bkashUrl});
}

class BkashExecuteResult {
  final String trxId;
  final String paymentId;
  final String status;
  const BkashExecuteResult({
    required this.trxId,
    required this.paymentId,
    required this.status,
  });
}

class BkashPaymentService {
  BkashPaymentService._();
  static final BkashPaymentService instance = BkashPaymentService._();
  factory BkashPaymentService() => instance;

  String? _idToken;
  // ignore: unused_field
  String? _refreshToken;

  Future<BkashTokenResult> grantToken() async {
    final uri = Uri.parse(
      '${AppConstants.bkashBaseUrl}/checkout/token/grant',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'username': AppConstants.bkashUsername,
            'password': AppConstants.bkashPassword,
          },
          body: jsonEncode({
            'app_key': AppConstants.bkashAppKey,
            'app_secret': AppConstants.bkashAppSecret,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        'bKash grantToken failed [${response.statusCode}]: '
        '${body['statusMessage'] ?? response.body}',
      );
    }

    final idToken = body['id_token'] as String?;
    final refreshToken = body['refresh_token'] as String?;

    if (idToken == null || refreshToken == null) {
      throw Exception('bKash grantToken: missing tokens in response');
    }

    _idToken = idToken;
    _refreshToken = refreshToken;

    return BkashTokenResult(idToken: idToken, refreshToken: refreshToken);
  }

  // Create Payment
  Future<BkashPaymentResult> createPayment({
    required double amount,
    required String merchantInvoiceNumber,
    String? payerReference,
  }) async {
    if (_idToken == null) {
      throw Exception('bKash createPayment: call grantToken() first');
    }

    final uri = Uri.parse(
      '${AppConstants.bkashBaseUrl}/checkout/create',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'authorization': _idToken!,
            'x-app-key': AppConstants.bkashAppKey,
          },
          body: jsonEncode({
            'mode': '0011',
            'payerReference': payerReference ?? '01770618575',
            'callbackURL': AppConstants.bkashCallbackUrl,
            'amount': amount.toStringAsFixed(2),
            'currency': 'BDT',
            'intent': 'sale',
            'merchantInvoiceNumber': merchantInvoiceNumber,
          }),
        )
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        'bKash createPayment failed [${response.statusCode}]: '
        '${body['statusMessage'] ?? response.body}',
      );
    }

    final statusCode = body['statusCode'] as String?;
    if (statusCode != '0000') {
      throw Exception(
        'bKash createPayment error: ${body['statusMessage'] ?? body}',
      );
    }

    final paymentId = body['paymentID'] as String?;
    final bkashUrl = body['bkashURL'] as String?;

    if (paymentId == null || bkashUrl == null) {
      throw Exception('bKash createPayment: missing paymentID or bkashURL');
    }

    return BkashPaymentResult(paymentId: paymentId, bkashUrl: bkashUrl);
  }

  //Execute Payment

  Future<BkashExecuteResult> executePayment(String paymentId) async {
    if (_idToken == null) {
      throw Exception('bKash executePayment: no active token');
    }

    final uri = Uri.parse(
      '${AppConstants.bkashBaseUrl}/checkout/execute',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'authorization': _idToken!,
            'x-app-key': AppConstants.bkashAppKey,
          },
          body: jsonEncode({'paymentID': paymentId}),
        )
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        'bKash executePayment failed [${response.statusCode}]: '
        '${body['statusMessage'] ?? response.body}',
      );
    }

    final statusCode = body['statusCode'] as String?;
    if (statusCode != '0000') {
      throw Exception(
        'bKash executePayment error: ${body['statusMessage'] ?? body}',
      );
    }

    final trxId = body['trxID'] as String?;
    if (trxId == null) {
      throw Exception('bKash executePayment: missing trxID');
    }

    return BkashExecuteResult(
      trxId: trxId,
      paymentId: paymentId,
      status: body['transactionStatus'] as String? ?? 'Completed',
    );
  }

  Future<Map<String, dynamic>> queryPayment(String paymentId) async {
    if (_idToken == null) {
      throw Exception('bKash queryPayment: no active token');
    }

    final uri = Uri.parse(
      '${AppConstants.bkashBaseUrl}/checkout/payment/status',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'authorization': _idToken!,
            'x-app-key': AppConstants.bkashAppKey,
          },
          body: jsonEncode({'paymentID': paymentId}),
        )
        .timeout(const Duration(seconds: 30));

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<BkashPaymentResult> initiate({
    required double amount,
    required String invoiceNumber,
  }) async {
    await grantToken();
    return createPayment(
      amount: amount,
      merchantInvoiceNumber: invoiceNumber,
    );
  }

  static String generateInvoiceNumber(String prefix) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$prefix$ts';
  }

  void clearTokens() {
    _idToken = null;
    _refreshToken = null;
  }
}

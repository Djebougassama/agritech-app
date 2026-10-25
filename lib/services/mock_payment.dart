
import 'dart:math';
import 'package:uuid/uuid.dart';

class MockPaymentService {
  static Future<Map<String, dynamic>> processPayment({
    required String provider,
    required String phone,
    required String password,
    required double amount,
  }) async {
    await Future.delayed(Duration(seconds: 2));

    
    final isSuccess = password.length >= 4 && password != "0000";

    return {
      'success': isSuccess,
      'transaction_id': isSuccess ? 'TRX_${DateTime.now().millisecondsSinceEpoch}' : null,
      'message': isSuccess
          ? 'Paiement de $amount GNF réussi via $provider'
          : 'Échec : Code secret incorrect',
    };
  }
}
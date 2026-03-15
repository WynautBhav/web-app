import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class MlService {
  static final _random = Random();

  static Future<Map<String, dynamic>?> scorePayment({
    required String upiId,
    required double amount,
  }) async {
    try {
      final payload = {
        'txn_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'amount_inr': amount,
        'amount_scaled': (amount / 20000).clamp(0.0, 10.0),
        'hour': DateTime.now().hour,
        'velocity_60s': _random.nextDouble() * 5,
        'is_new_device': 1,
        'is_new_recipient': 1,
        'account_age_days': _random.nextInt(500) + 1,
        'city_risk_score': 0.5,
        'is_festival_day': 0,
        'is_sim_swap_signal': 0,
        'is_round_amount': amount % 1000 == 0 ? 1 : 0,
        'cat_crypto': 0,
        'cat_grocery': 1,
        'V14': -2.5,
        'V4': 1.0,
        'V12': -1.5,
        'V10': -1.0,
        'V11': -0.5,
      };

      final response = await http.post(
        Uri.parse('${AppConfig.mlBaseUrl}/score'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.mlBaseUrl}/health'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static String riskLevelFromScore(Map<String, dynamic> result) {
    final level = result['risk_level'] as String? ?? 'LOW';
    return level.toUpperCase();
  }

  static List<String> limeReasons(Map<String, dynamic> result) {
    final lime = result['lime'] as List<dynamic>? ?? [];
    return lime
        .where((item) => item['direction'] == 'RISK')
        .map((item) => _humanReadable(item['feature'] as String))
        .take(3)
        .toList();
  }

  static String _humanReadable(String feature) {
    if (feature.contains('velocity_60s'))
      return 'Multiple payments in short time';
    if (feature.contains('is_new_device'))
      return 'New device never used before';
    if (feature.contains('hour'))
      return 'Unusual payment time';
    if (feature.contains('is_new_recipient'))
      return 'You have never paid this person';
    if (feature.contains('amount'))
      return 'Amount is higher than usual';
    if (feature.contains('velocity_log'))
      return 'Rapid transaction pattern detected';
    if (feature.contains('v_fraud_signal'))
      return 'Suspicious transaction signature';
    if (feature.contains('account_age'))
      return 'Recipient account is very new';
    return feature.split('>').first.trim().replaceAll('_', ' ');
  }
}

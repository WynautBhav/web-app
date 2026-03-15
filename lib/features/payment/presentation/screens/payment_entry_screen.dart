import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/widgets/keyboard_dismissible.dart';
import '../../../../services/gemini_service.dart';
import '../../../../services/phone_lookup_service.dart';
import '../../../../services/ml_service.dart';

class PaymentEntryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  
  const PaymentEntryScreen({super.key, this.initialData});

  @override
  ConsumerState<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends ConsumerState<PaymentEntryScreen> {
  final _upiController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();
  bool _isLoading = false;
  bool _showQRScanner = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null) {
      // Handle UPI ID
      if (data['upiId'] != null && (data['upiId'] as String).isNotEmpty) {
        _upiController.text = data['upiId'] as String;
      }
      // Handle phone number from contacts
      else if (data['phone'] != null && (data['phone'] as String).isNotEmpty) {
        _upiController.text = data['phone'] as String;
      }
      if (data['amount'] != null) {
        _amountController.text = data['amount'].toString();
      }
      if (data['remark'] != null) {
        _remarkController.text = data['remark'] as String;
      }
      if (data['scanQR'] == true) {
        // Auto-open scanner when launched from Scan QR shortcut
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _showQRScanner = true);
        });
      }
    }
  }

  @override
  void dispose() {
    _upiController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _analyzePayment() async {
    var input = _upiController.text.trim();
    final amountText = _amountController.text.trim();

    if (input.isEmpty) {
      _showError('Please enter UPI ID or Mobile Number');
      return;
    }

    if (amountText.isEmpty) {
      _showError('Please enter amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    if (amount > 100000) {
      _showError('Maximum amount allowed is ₹1,00,000');
      return;
    }

    setState(() => _isLoading = true);

    // Check if input is a phone number and look up UPI
    String upiId = input;
    String recipientName = input;
    
    final phoneRegex = RegExp(r'^[+\d\s\-()]{10,}$');
    if (phoneRegex.hasMatch(input)) {
      // It's a phone number - look up UPI ID
      try {
        final phoneInfo = await PhoneLookupService.lookupPhone(input);
        if (phoneInfo != null && phoneInfo['upiId'] != null) {
          upiId = phoneInfo['upiId']!;
          recipientName = phoneInfo['name'] ?? input;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Found UPI: $upiId'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        }
      } catch (e) {
        // Continue with phone number as is
      }
    } else {
      // Validate UPI format
      final upiRegex = RegExp(r'^[a-zA-Z0-9@._-]+$');
      if (!upiRegex.hasMatch(input)) {
        _showError('Please enter a valid UPI ID or Mobile Number');
        setState(() => _isLoading = false);
        return;
      }
      recipientName = input.split('@').first;
    }

    try {
      // Try ML backend first
      final mlResult = await MlService.scorePayment(
        upiId: upiId,
        amount: amount,
      );

      if (mlResult != null) {
        final level = MlService.riskLevelFromScore(mlResult);
        final reasons = MlService.limeReasons(mlResult);
        final mlScore = (mlResult['score'] as num).toInt();

        final riskScore = RiskScore(
          score: mlScore,
          level: level.toLowerCase(),
          explanation: reasons.isNotEmpty
              ? reasons.join('. ')
              : 'This payment has been analysed by FraudShield AI.',
          action: level == 'HIGH'
              ? 'block'
              : level == 'MEDIUM'
                  ? 'warn'
                  : 'allow',
          flags: reasons,
        );

        if (!mounted) return;
        if (riskScore.score >= 40) {
          context.push('/payment-risk', extra: {
            'riskScore': riskScore,
            'paymentData': {
              'upiId': upiId,
              'name': recipientName,
              'amount': amount,
            },
          });
        } else {
          context.push('/payment-safe', extra: {
            'upiId': upiId,
            'name': recipientName,
            'amount': amount,
            'riskScore': riskScore,
          });
        }
        return;
      }

      // Fall back to Gemini if ML backend is unreachable
      final geminiService = ref.read(geminiServiceProvider);
      final random = Random();
      
      final riskScore = await geminiService.scorePayment(
        recipientUpiId: upiId,
        recipientName: recipientName,
        amount: amount,
        userMonthlyAvg: 3500,
        recipientAccountAgeDays: random.nextInt(1000) + 1,
        pastTransactionCount: random.nextInt(500),
      );

      if (!mounted) return;

      if (riskScore.score >= 60) {
        context.push('/payment-risk', extra: {
          'riskScore': riskScore,
          'paymentData': {
            'upiId': upiId,
            'name': upiId.split('@').first,
            'amount': amount,
          },
        });
      } else {
        context.push('/payment-safe', extra: {
          'upiId': upiId,
          'name': upiId.split('@').first,
          'amount': amount,
          'riskScore': riskScore,
        });
      }
    } catch (e) {
      _showError('Failed to analyze payment. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  void _parseUpiQr(String code) {
    try {
      final uri = Uri.parse(code);
      if (uri.scheme == 'upi') {
        final pa = uri.queryParameters['pa'];
        final pn = uri.queryParameters['pn'];
        final am = uri.queryParameters['am'];

        if (pa != null) _upiController.text = pa;
        if (am != null) _amountController.text = am;
        
        setState(() => _showQRScanner = false);
      }
    } catch (e) {
      _showError('Invalid QR code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Send Money'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: KeyboardDismissible(
        child: _showQRScanner ? _buildQRScanner() : _buildForm(),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _parseUpiQr(barcodes.first.rawValue!);
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextButton(
            onPressed: () => setState(() => _showQRScanner = false),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protected by Argus Eye',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Every payment is scored before it leaves',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _upiController,
                  decoration: InputDecoration(
                    labelText: 'UPI ID or Mobile Number',
                    hintText: 'name@upi or +91 XXXXX XXXXX',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount (₹)',
                    hintText: 'Enter amount',
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _remarkController,
                  decoration: InputDecoration(
                    labelText: 'Remark (optional)',
                    hintText: "What's this for?",
                    prefixIcon: const Icon(Icons.note_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.slate300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('OR', style: TextStyle(color: AppColors.slate400)),
              ),
              Expanded(child: Divider(color: AppColors.slate300)),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _showQRScanner = true),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Point at any UPI QR code',
                    style: TextStyle(fontSize: 13, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _analyzePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Analyse & Proceed',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

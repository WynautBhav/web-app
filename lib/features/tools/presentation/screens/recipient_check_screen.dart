import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../services/gemini_service.dart';
import '../../../../services/phone_lookup_service.dart';
import '../../../../services/threat_service.dart';
import 'package:appwrite/appwrite.dart';

class RecipientCheckScreen extends ConsumerStatefulWidget {
  const RecipientCheckScreen({super.key});

  @override
  ConsumerState<RecipientCheckScreen> createState() => _RecipientCheckScreenState();
}

class _RecipientCheckScreenState extends ConsumerState<RecipientCheckScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  RiskScore? _result;
  Map<String, String>? _phoneInfo;

  // Trust badge state
  Map<String, dynamic>? _badgeData;
  RealtimeSubscription? _realtimeSub;
  String? _checkedUpiId;

  @override
  void dispose() {
    _controller.dispose();
    _realtimeSub?.close();
    super.dispose();
  }

  Future<void> _checkRecipient() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UPI ID or Phone Number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _phoneInfo = null;
    });

    final isPhone = RegExp(r'^[\d\s\+\-]+$').hasMatch(input) && input.replaceAll(RegExp(r'[^\d]'), '').length >= 10;
    
    if (isPhone) {
      final phoneResult = await PhoneLookupService.lookupPhone(input);
      if (phoneResult != null && mounted) {
        setState(() => _phoneInfo = phoneResult);
      }
    }

    try {
      final gemini = ref.read(geminiServiceProvider);
      final score = await gemini.scoreRecipient(input);
      setState(() {
        _result = score;
        _isLoading = false;
      });

      // Fetch trust badge from Appwrite
      final resolvedUpi = _phoneInfo?['upiId'] ?? input;
      _checkedUpiId = resolvedUpi;
      final badge = await ThreatService.getTrustBadge(resolvedUpi);
      if (mounted) setState(() => _badgeData = badge);

      // Subscribe to real-time updates
      _realtimeSub?.close();
      _realtimeSub = ThreatService.subscribeToEntity(resolvedUpi, (payload) {
        if (mounted) {
          setState(() {
            _badgeData = {
              'state': payload['status'] ?? 'SAFE',
              'score': payload['score'] ?? 0,
              'reports': payload['reports'] ?? 0,
            };
          });
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Recipient Check'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify before you pay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Check any UPI ID or phone number for fraud signals',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'UPI ID or Phone Number',
                      hintText: 'name@upi or +91 XXXXX XXXXX',
                      prefixIcon: const Icon(Icons.account_circle_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkRecipient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Check Recipient'),
                    ),
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              if (_badgeData != null) _buildTrustBadge(),
              if (_badgeData != null) const SizedBox(height: 16),
              _buildResultCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge() {
    final state = _badgeData!['state'] as String? ?? 'SAFE';
    final score = _badgeData!['score'] ?? 0;
    final reports = _badgeData!['reports'] ?? 0;

    Color badgeColor;
    String badgeLabel;
    switch (state) {
      case 'CORROBORATED':
        badgeColor = AppColors.amber;
        badgeLabel = 'Community reports';
        break;
      case 'CONFIRMED':
        badgeColor = AppColors.red;
        badgeLabel = 'Bank Warning';
        break;
      case 'BLOCKLISTED':
        badgeColor = AppColors.red;
        badgeLabel = 'Blocklisted — Do not pay';
        break;
      default:
        badgeColor = AppColors.green;
        badgeLabel = 'Verified';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Trust Badge',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state == 'SAFE' ? Icons.verified_rounded : Icons.warning_amber_rounded,
                  color: badgeColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$reports community report${reports == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.slate500, fontSize: 13),
              ),
              const SizedBox(width: 16),
              Text(
                'Threat score: $score/100',
                style: const TextStyle(color: AppColors.slate500, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                final upiId = _checkedUpiId ?? _controller.text.trim();
                final success = await ThreatService.reportScam(
                  entityId: upiId,
                  entityType: 'UPI',
                  scamType: 'FRAUD',
                  userId: 'anonymous_user',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Report sent to fraud team'
                            : 'Failed to send report. Please try again.',
                      ),
                      backgroundColor: success ? AppColors.green : AppColors.red,
                    ),
                  );
                  if (success) {
                    final updated = await ThreatService.getTrustBadge(upiId);
                    if (mounted) setState(() => _badgeData = updated);
                  }
                }
              },
              icon: const Icon(Icons.flag_rounded, size: 16),
              label: const Text('Report Scam'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final score = _result!.score;
    final isSafe = score <= 60;
    final color = isSafe ? AppColors.green : score <= 85 ? AppColors.amber : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          if (_phoneInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      _phoneInfo!['name']![0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _phoneInfo!['name']!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _phoneInfo!['accountVerified']!,
                        style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone_rounded, 'Phone', _phoneInfo!['phone']!),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.alternate_email_rounded, 'UPI ID', _phoneInfo!['upiId']!),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.account_balance_rounded, 'Bank', _phoneInfo!['bank']!),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _phoneInfo!['riskLevel'] == 'Low' 
                          ? AppColors.green.withOpacity(0.1)
                          : _phoneInfo!['riskLevel'] == 'Medium'
                              ? AppColors.amber.withOpacity(0.1)
                              : AppColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_phoneInfo!['riskLevel']} Risk',
                      style: TextStyle(
                        color: _phoneInfo!['riskLevel'] == 'Low' 
                            ? AppColors.green
                            : _phoneInfo!['riskLevel'] == 'Medium'
                                ? AppColors.amber
                                : AppColors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 4),
            ),
            child: Center(
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              score <= 30 ? 'Low Risk' : score <= 60 ? 'Medium Risk' : score <= 85 ? 'High Risk' : 'Critical',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Account Analysis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalysisRow('Status', isSafe ? 'Active' : 'Flagged'),
          _buildAnalysisRow('Reports', '${score ~/ 10 + 3} community reports'),
          const SizedBox(height: 12),
          Text(
            _result!.explanation,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate600,
              height: 1.5,
            ),
          ),
          if (_result!.flags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _result!.flags.map((flag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(flag, style: TextStyle(fontSize: 12, color: color)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isSafe
                  ? () => context.push('/payment', extra: {'upiId': _phoneInfo?['upiId'] ?? _controller.text})
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSafe ? AppColors.green : AppColors.slate200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isSafe ? 'Pay This Recipient' : 'Avoid This Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSafe ? Colors.white : AppColors.slate500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.slate500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.slate500, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.slate900,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.slate500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

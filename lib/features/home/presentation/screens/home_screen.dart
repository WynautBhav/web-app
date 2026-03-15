import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fast_contacts/fast_contacts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../services/anomaly_detector.dart';
import '../../../../services/biometric_service.dart';
import '../../../home/presentation/providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final isLocalFrozen = ref.watch(accountFreezeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/payment'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: const Row(
            children: [
              Icon(Icons.send_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Send Money',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (user) => (user.isAccountFrozen || isLocalFrozen) ? _buildFreezeBanner() : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (user) => _buildHeader(user.name),
                  loading: () => _buildHeader('Loading...'),
                  error: (_, __) => _buildHeader('User'),
                ),
              ),
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (user) => _buildBalanceCard(user),
                  loading: () => _buildBalanceCard(null),
                  error: (_, __) => _buildBalanceCard(null),
                ),
              ),
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (user) => _buildFraudSavingsCard(user),
                  loading: () => _buildFraudSavingsCard(null),
                  error: (_, __) => _buildFraudSavingsCard(null),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),
              SliverToBoxAdapter(
                child: userAsync.when(
                  data: (user) => _buildSecurityStatus(user),
                  loading: () => _buildSecurityStatus(null),
                  error: (_, __) => _buildSecurityStatus(null),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildRecentAlerts(),
              ),
              SliverToBoxAdapter(
                child: _buildScamEducation(),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFreezeBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.slate800,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Frozen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your account is currently frozen. Tap to unfreeze.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showFreezeDialog(context),
            icon: const Icon(Icons.lock_open_rounded, color: AppColors.slate900),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.slate600, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science_rounded, size: 12, color: AppColors.amber),
                    SizedBox(width: 4),
                    Text(
                      'DEMO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.go('/notifications'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Icon(Icons.notifications_rounded, color: AppColors.slate600, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.slate600, size: 22),
      ),
    );
  }

  Widget _buildBalanceCard(User? user) {
    final isLocalFrozen = ref.watch(accountFreezeProvider);
    final isFrozen = (user?.isAccountFrozen ?? false) || isLocalFrozen;
    final balance = user?.accountBalance ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              AppColors.slate100,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate200.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: AppColors.slate400,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Account Balance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.contactless_rounded,
                  size: 20,
                  color: AppColors.slate300,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '₹${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.go('/transactions'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Transactions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFraudSavingsCard(User? user) {
    final fraudPrevented = user?.fraudPrevented ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
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
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fraud Prevention',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: fraudPrevented),
                        duration: const Duration(milliseconds: 1500),
                        builder: (context, value, child) {
                          return Text(
                            '₹${value.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                              letterSpacing: -1,
                            ),
                          );
                        },
                      ),
                      const Text(
                        'saved from scams this month',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.slate900,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('12', 'Payments Scanned'),
                Container(width: 1, height: 30, color: AppColors.slate200),
                _buildMiniStat('3', 'Blocked'),
                Container(width: 1, height: 30, color: AppColors.slate200),
                _buildMiniStat('₹${fraudPrevented.toStringAsFixed(0)}', 'Saved'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.contacts_rounded,
                  label: 'Contacts',
                  color: AppColors.slate600,
                  onTap: () => _showContactPicker(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.alternate_email_rounded,
                  label: 'UPI ID',
                  color: AppColors.slate600,
                  onTap: () => _showUpiIdInput(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan QR',
                  color: AppColors.slate600,
                  onTap: () => context.push('/payment', extra: {'scanQR': true}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.security_rounded,
                  label: 'Alert',
                  color: AppColors.primary,
                  onTap: () => _showSmartAlert(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatus(User? user) {
    final score = user?.securityScore ?? 850;
    final scoreLabel = _getScoreLabel(score);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security Score',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your account safety is performing at peak efficiency. 2-factor authentication is active.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showOptimizationGuide(context),
                    child: Row(
                      children: [
                        Text(
                          'Optimization Guide',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.slate600),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: score / 1000,
                      strokeWidth: 8,
                      backgroundColor: AppColors.slate100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score >= 800 ? AppColors.slate900 : (score >= 600 ? AppColors.slate600 : AppColors.slate400),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                      Text(
                        'Points',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptimizationGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Security Optimization', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('• Turn on biometric authentication for payments.\n• Review recent transactions regularly.\n• Never share your UPI PIN or OTP.\n• Use the link scanner before opening unknown URLs.', style: TextStyle(height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate900),
                child: const Text('Got It'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 800) return AppColors.slate900;
    if (score >= 600) return AppColors.slate600;
    return AppColors.slate400;
  }

  String _getScoreLabel(int score) {
    if (score >= 800) return 'Excellent';
    if (score >= 600) return 'Good';
    if (score >= 400) return 'Fair';
    return 'Poor';
  }

  Widget _buildStatusItem(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? AppColors.slate900 : AppColors.slate100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? Icons.check_rounded : Icons.close_rounded,
            color: isActive ? Colors.white : AppColors.slate400,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.slate700 : AppColors.slate400,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlerts() {
    final anomalyDetector = AnomalyDetector();
    final historicalAmounts = [500.0, 1200.0, 800.0, 1500.0, 600.0, 2000.0, 450.0, 900.0];
    final sampleAmount = 8500.0;
    final anomalyResult = anomalyDetector.analyze(sampleAmount, historicalAmounts);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/notifications'),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            icon: Icons.login_rounded,
            title: 'New Login Detected',
            subtitle: 'Chrome on Android • Mumbai, IN',
            time: '2 min ago',
            isSafe: true,
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            icon: Icons.shield_rounded,
            title: 'System Scan Complete',
            subtitle: 'No threats detected',
            time: '1 hour ago',
            isSafe: true,
          ),
          const SizedBox(height: 12),
          _buildAlertCard(
            icon: anomalyResult.isAnomalous ? Icons.warning_rounded : Icons.info_rounded,
            title: anomalyResult.isAnomalous ? 'Unusual Payment Pattern' : 'Payment Analysis',
            subtitle: anomalyResult.explanation,
            time: '3 hours ago',
            isSafe: !anomalyResult.isAnomalous,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isSafe,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSafe ? AppColors.slate100 : AppColors.slate200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSafe ? AppColors.slate900 : AppColors.slate700,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScamEducation() {
    final scamCards = [
      {
        'title': 'Digital Arrest',
        'desc': 'Scammers pose as police claiming legal issues. Real authorities never ask for money over phone.',
        'color': AppColors.slate800,
        'icon': Icons.gavel_rounded,
      },
      {
        'title': 'UPI Fraud',
        'desc': 'Never share your UPI PIN or OTP. Fraudsters impersonate support to steal credentials.',
        'color': AppColors.slate700,
        'icon': Icons.currency_rupee_rounded,
      },
      {
        'title': 'Fake Investment',
        'desc': 'Too-good-to-be-true returns on investments are usually scams. Verify before investing.',
        'color': AppColors.slate600,
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Loan Scam',
        'desc': 'Instant loans with no documents are traps. Stick to trusted banks and NBFCs.',
        'color': AppColors.slate500,
        'icon': Icons.account_balance_rounded,
      },
      {
        'title': 'OTP Sharing',
        'desc': 'Never share OTPs with anyone. Banks never ask for your OTP over call.',
        'color': AppColors.slate400,
        'icon': Icons.sms_rounded,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stay Informed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: scamCards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final card = scamCards[index];
                return GestureDetector(
                  onTap: () => _showScamDetails(context, card),
                  child: Container(
                  width: 260,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (card['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (card['color'] as Color).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: card['color'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              card['icon'] as IconData,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              card['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: card['color'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Text(
                          card['desc'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.slate600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showScamDetails(BuildContext context, Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: card['color'] as Color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    card['icon'] as IconData,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  card['title'] as String,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: card['color'] as Color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              card['desc'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.slate600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.slate900),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stay vigilant! Never share personal information with unknown callers.',
                      style: TextStyle(color: AppColors.slate600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got It'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFreezeDialog(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final isLocalFrozen = ref.watch(accountFreezeProvider);
    final isFrozen = (userAsync.valueOrNull?.isAccountFrozen ?? false) || isLocalFrozen;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFrozen ? Icons.lock_open_rounded : Icons.lock_rounded,
                color: AppColors.slate800,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFrozen ? 'Unfreeze Account?' : 'Freeze Account?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isFrozen
                  ? 'Your account will be unfrozen and you can make payments again.'
                  : 'This will temporarily block all outgoing payments. Use this if you suspect fraud.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.slate500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final biometricService = BiometricService();
                  final authenticated = await biometricService.authenticate(
                    reason: isFrozen ? 'Authenticate to unfreeze account' : 'Authenticate to freeze account',
                  );
                  if (!authenticated) return;

                  try {
                    // Update both global and local state
                    ref.read(accountFreezeProvider.notifier).state = !isFrozen;
                    await ref.read(userRepositoryProvider).toggleAccountFreeze();
                    ref.invalidate(userProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFrozen ? 'Account unfrozen successfully!' : 'Account frozen for your security.'),
                          backgroundColor: isFrozen ? AppColors.slate900 : AppColors.slate800,
                        ),
                      );
                    }
                  } catch (e) {
                    // Revert local state if failed
                    ref.read(accountFreezeProvider.notifier).state = isFrozen;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update account status'),
                          backgroundColor: AppColors.slate500,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFrozen ? AppColors.slate900 : AppColors.slate800,
                ),
                child: Text(isFrozen ? 'Unfreeze Account' : 'Freeze Account'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactPicker(BuildContext context) async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact permission required to show contacts.'),
            backgroundColor: AppColors.amber,
          ),
        );
      }
      return;
    }

    List<dynamic> contacts = [];
    try {
      final fetchedContacts = await FastContacts.getAllContacts();
      contacts = fetchedContacts.where((c) => c.phones.isNotEmpty).toList();
      contacts.sort((a, b) => a.displayName.compareTo(b.displayName));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Pay Contact', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate900)),
              const SizedBox(height: 16),
              Expanded(
                child: contacts.isEmpty
                    ? const Center(child: Text('No contacts found', style: TextStyle(color: AppColors.slate500)))
                    : ListView.separated(
                        itemCount: contacts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          final phone = contact.phones.first.number;
                          final initial = contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                initial,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            title: Text(contact.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/payment', extra: {'phone': phone, 'name': contact.displayName});
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showUpiIdInput(BuildContext context) {
    final upiController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pay UPI ID', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.slate900)),
            const SizedBox(height: 16),
            TextField(
              controller: upiController,
              decoration: InputDecoration(
                hintText: 'name@upi',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final upi = upiController.text.trim();
                  if (upi.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a UPI ID')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  context.push('/payment', extra: {'upiId': upi});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Proceed to Pay'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ],
        ),
      ),
    );
  }

  void _showSmartAlert(BuildContext context) {
    final anomalyDetector = AnomalyDetector();
    final historicalAmounts = [500.0, 1200.0, 800.0, 1500.0, 600.0, 2000.0, 450.0, 900.0];
    final recentAmounts = [8500.0, 350.0, 15000.0];
    
    final results = recentAmounts.map((amt) => {
      'amount': amt,
      'result': anomalyDetector.analyze(amt, historicalAmounts),
    }).toList();

    final anomalousCount = results.where((r) => (r['result'] as AnomalyResult).isAnomalous).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: anomalousCount > 0 ? AppColors.primary.withOpacity(0.1) : AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                anomalousCount > 0 ? Icons.warning_rounded : Icons.check_circle_rounded,
                color: anomalousCount > 0 ? AppColors.primary : AppColors.slate900,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              anomalousCount > 0
                  ? '$anomalousCount Suspicious Transaction${anomalousCount > 1 ? 's' : ''} Found'
                  : 'All Clear — No Anomalies',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...results.map((r) {
              final amount = r['amount'] as double;
              final result = r['result'] as AnomalyResult;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.isAnomalous ? AppColors.primary.withOpacity(0.05) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: result.isAnomalous ? AppColors.primary.withOpacity(0.2) : AppColors.slate200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      result.isAnomalous ? Icons.warning_rounded : Icons.check_rounded,
                      color: result.isAnomalous ? AppColors.primary : AppColors.slate600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            result.explanation,
                            style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got It'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkCheckerDialog(BuildContext context) {
    final linkController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.slate200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_rounded,
                color: AppColors.slate600,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Link Safety Checker',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter a URL to check if it\'s safe to visit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate500,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: linkController,
              decoration: InputDecoration(
                hintText: 'https://example.com',
                prefixIcon: const Icon(Icons.link_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final link = linkController.text.trim();
                  if (link.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a URL')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  _showLinkResult(context, link);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.slate700,
                ),
                child: const Text('Check Link'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkResult(BuildContext context, String url) {
    final isSafe = _analyzeLink(url);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSafe ? AppColors.slate100 : AppColors.slate300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSafe ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: isSafe ? AppColors.slate900 : AppColors.slate500,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSafe ? 'Link Looks Safe' : 'Warning: Suspicious Link',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSafe ? AppColors.slate100 : AppColors.slate300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSafe ? Icons.info_outline : Icons.security_rounded,
                    color: isSafe ? AppColors.slate900 : AppColors.slate500,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isSafe 
                          ? 'This link appears to be safe. However, always be cautious with personal information.'
                          : 'This link has been flagged as potentially dangerous. Do not enter any personal information.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSafe ? AppColors.slate900 : AppColors.slate500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  bool _analyzeLink(String url) {
    final lowerUrl = url.toLowerCase();
    final suspiciousPatterns = ['login', 'verify', 'secure', 'update', 'confirm', 'bank', 'account'];
    final suspiciousDomains = ['.xyz', '.top', '.click', '.link', '.work', '.gq', '.ml', '.cf', '.tk'];
    
    bool hasSuspiciousPattern = suspiciousPatterns.any((p) => lowerUrl.contains(p));
    bool hasSuspiciousDomain = suspiciousDomains.any((d) => lowerUrl.contains(d));
    
    return !(hasSuspiciousPattern && hasSuspiciousDomain);
  }

  void _showSOSDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.slate300,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sos_rounded,
                color: AppColors.slate500,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Emergency SOS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will:\n• Freeze your account\n• Alert emergency contacts\n• Log fraud event',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(userRepositoryProvider).toggleAccountFreeze();
                    ref.invalidate(userProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emergency alert sent! Account frozen.'),
                          backgroundColor: AppColors.slate500,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to send SOS alert. Please try again.'),
                          backgroundColor: AppColors.slate500,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.slate500,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Activate SOS'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

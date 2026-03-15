import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../services/gemini_service.dart';
import '../../../../services/biometric_service.dart';
import '../../../home/presentation/providers/home_provider.dart';

class ToolsScreen extends ConsumerStatefulWidget {
  const ToolsScreen({super.key});

  @override
  ConsumerState<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends ConsumerState<ToolsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildProtectionTools(),
            ),
            SliverToBoxAdapter(
              child: _buildScamTools(),
            ),
            SliverToBoxAdapter(
              child: _buildFamilyProtection(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              const Text(
                'Protection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Icon(Icons.more_horiz_rounded, color: AppColors.slate600, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                Icon(Icons.gpp_maybe_rounded, size: 48, color: AppColors.slate600),
                SizedBox(height: 12),
                Text(
                  'System Secure',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Last scanned 2 minutes ago',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Protection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  icon: Icons.lock_rounded,
                  title: 'Freeze Account',
                  subtitle: 'Block all payments',
                  color: AppColors.slate800,
                  onTap: () {
                    final isFrozen = ref.read(userProvider).valueOrNull?.isAccountFrozen ?? false;
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
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(color: AppColors.slate100, shape: BoxShape.circle),
                              child: Icon(isFrozen ? Icons.lock_open_rounded : Icons.lock_rounded, color: AppColors.slate800, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(isFrozen ? 'Unfreeze Account?' : 'Freeze Account?',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                              isFrozen
                                  ? 'Your account will be unfrozen and you can make payments again.'
                                  : 'All outgoing payments will be blocked immediately. Use this if you suspect fraud.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: AppColors.slate500),
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

                                  await ref.read(userRepositoryProvider).toggleAccountFreeze();
                                  ref.invalidate(userProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                      content: Text(isFrozen ? 'Account unfrozen!' : 'Account frozen for your protection.'),
                                      backgroundColor: AppColors.slate800,
                                    ));
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate800),
                                child: Text(isFrozen ? 'Unfreeze Account' : 'Freeze Account'),
                              ),
                            ),
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToolCard(
                  icon: Icons.sos_rounded,
                  title: 'Emergency SOS',
                  subtitle: 'Instant help',
                  color: AppColors.slate900,
                  onTap: () {
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
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(color: AppColors.slate100, shape: BoxShape.circle),
                              child: const Icon(Icons.sos_rounded, color: AppColors.slate900, size: 40),
                            ),
                            const SizedBox(height: 16),
                            const Text('Emergency Fraud SOS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text(
                              'Activating SOS will freeze your account and connect you to the Cyber Crime Helpline.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: AppColors.slate500),
                            ),
                            const SizedBox(height: 20),
                            _sosActionTile(Icons.lock_rounded, 'Freeze account immediately', AppColors.slate800),
                            _sosActionTile(Icons.phone_rounded, 'Call Cyber Crime Helpline: 1930', AppColors.slate900),
                            _sosActionTile(Icons.emergency_rounded, 'National Emergency: 112', AppColors.slate800),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await ref.read(userRepositoryProvider).toggleAccountFreeze();
                                  ref.invalidate(userProvider);
                                  await launchUrl(Uri.parse('tel:1930'), mode: LaunchMode.externalApplication);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.slate800,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Freeze & Call 1930', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScamTools() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scam Detection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          _buildToolListTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'QR Code Scanner',
            subtitle: 'Verify before you pay',
            color: AppColors.slate900,
            onTap: () => context.push('/payment'),
          ),
          const SizedBox(height: 12),
          _buildToolListTile(
            icon: Icons.link_rounded,
            title: 'Link Checker',
            subtitle: 'Scan suspicious URLs',
            color: AppColors.slate700,
            onTap: () => _showLinkCheckerSheet(context),
          ),
          const SizedBox(height: 12),
          _buildToolListTile(
            icon: Icons.sms_rounded,
            title: 'Message Analyser',
            subtitle: 'Paste any suspicious SMS or WhatsApp message',
            color: AppColors.slate600,
            onTap: () => _showMessageAnalyserSheet(context),
          ),
          const SizedBox(height: 12),
          _buildToolListTile(
            icon: Icons.person_search_rounded,
            title: 'Recipient Check',
            subtitle: 'Verify UPI ID/phone',
            color: AppColors.primary,
            onTap: () => context.push('/recipient-check'),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyProtection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Family Protection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
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
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Network',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '2 members protected',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildFamilyMember('Mom', true),
                    const SizedBox(width: 12),
                    _buildFamilyMember('Dad', true),
                    const SizedBox(width: 12),
                    _buildAddMember(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.slate400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMember(String name, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name[0],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.slate900,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMember() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final nameController = TextEditingController();
          final phoneController = TextEditingController();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Family Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name', prefixIcon: const Icon(Icons.person_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 12),
                    TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${nameController.text.trim()} added to your family network'), backgroundColor: AppColors.slate900));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Add Member'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.slate300,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.slate500,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLinkCheckerSheet(BuildContext context) {
    final urlController = TextEditingController();
    bool isLoading = false;
    RiskScore? result;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.slate200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.link_rounded, color: AppColors.slate700),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Phishing Link Scanner',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste any suspicious URL to check if it\'s safe',
                style: TextStyle(fontSize: 14, color: AppColors.slate500),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: urlController,
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
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (urlController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a URL')),
                            );
                            return;
                          }
                          setSheetState(() => isLoading = true);
                          try {
                            final gemini = ref.read(geminiServiceProvider);
                            final score = await gemini.scoreUrl(urlController.text.trim());
                            setSheetState(() {
                              result = score;
                              isLoading = false;
                            });
                          } catch (e) {
                            setSheetState(() => isLoading = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to check URL. Please try again.'),
                                  backgroundColor: AppColors.slate500,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.slate700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Check Link'),
                ),
              ),
              if (result != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: result!.score > 60 ? AppColors.slate800 : (result!.score > 30 ? AppColors.slate600 : AppColors.slate200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            result!.score > 60
                                ? Icons.warning_rounded
                                : result!.score > 30
                                    ? Icons.info_rounded
                                    : Icons.check_circle_rounded,
                            color: result!.score > 30
                                ? Colors.white
                                : AppColors.slate900,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result!.score > 60
                                  ? 'Dangerous Link Detected!'
                                  : result!.score > 30
                                      ? 'Suspicious Link'
                                      : 'This link appears safe',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: result!.score > 30
                                    ? Colors.white
                                    : AppColors.slate900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result!.explanation,
                        style: TextStyle(
                          fontSize: 13,
                          color: result!.score > 30 ? Colors.white70 : AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sosActionTile(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showMessageAnalyserSheet(BuildContext context) {
    final controller = TextEditingController();
    bool isLoading = false;
    RiskScore? result;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.slate600.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.sms_rounded, color: AppColors.slate600),
                  ),
                  const SizedBox(width: 12),
                  const Text('AI Message Analyser', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                const Text('Paste any suspicious SMS, WhatsApp, or email message below', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                const SizedBox(height: 16),
                TextField(controller: controller, maxLines: 5, decoration: InputDecoration(hintText: 'e.g. "Dear customer, your KYC has expired. Click here: bit.ly/sbi-kyc"', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: AppColors.slate100)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (controller.text.trim().isEmpty) return;
                      setSheetState(() => isLoading = true);
                      try {
                        final gemini = ref.read(geminiServiceProvider);
                        final score = await gemini.scoreMessage(controller.text.trim());
                        setSheetState(() { result = score; isLoading = false; });
                      } catch (_) {
                        setSheetState(() => isLoading = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to analyze message. Please try again.'),
                            backgroundColor: AppColors.slate500,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate600, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Analyse Message', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (result != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: result!.score > 60 ? AppColors.slate800 : result!.score > 30 ? AppColors.slate600 : AppColors.slate200, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(result!.score > 60 ? Icons.warning_rounded : result!.score > 30 ? Icons.info_rounded : Icons.check_circle_rounded, color: result!.score > 30 ? Colors.white : AppColors.slate900),
                          const SizedBox(width: 8),
                          Expanded(child: Text(result!.score > 60 ? 'Scam Detected!' : result!.score > 30 ? 'Suspicious Message' : 'Looks Safe', style: TextStyle(fontWeight: FontWeight.bold, color: result!.score > 30 ? Colors.white : AppColors.slate900))),
                        ]),
                        const SizedBox(height: 8),
                        Text(result!.explanation, style: TextStyle(fontSize: 13, color: result!.score > 30 ? Colors.white70 : AppColors.slate700)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

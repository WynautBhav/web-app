import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/home_provider.dart';

class QuickActionsWidget extends ConsumerWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.contacts_rounded,
                label: 'Pay Contact',
                color: AppColors.slate600,
                backgroundColor: AppColors.slate100,
                onTap: () => _showContactPicker(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.alternate_email_rounded,
                label: 'UPI ID',
                color: AppColors.slate600,
                backgroundColor: AppColors.slate100,
                onTap: () => context.push('/payment'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan',
                color: AppColors.slate600,
                backgroundColor: AppColors.slate100,
                onTap: () => context.push('/payment'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SosButton(
                onTap: () => _showSOSDialog(context, ref),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showContactPicker(BuildContext context) async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact permission is required to select a contact.'),
            backgroundColor: AppColors.slate500,
          ),
        );
      }
      return;
    }

    try {
      final contacts = await FastContacts.getAllContacts();
      // Filter out contacts without a usable phone number
      final validContacts = contacts.where((c) => c.phones.isNotEmpty).toList();
      
      // Sort alphabetically
      validContacts.sort((a, b) => (a.displayName).compareTo(b.displayName));

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
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
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Select Contact',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: validContacts.isEmpty
                      ? const Center(child: Text('No contacts with phone numbers found.'))
                      : ListView.builder(
                          itemCount: validContacts.length,
                          itemBuilder: (context, index) {
                            final contact = validContacts[index];
                            final initial = contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase()
                                : '?';
                            final phone = contact.phones.first.number;
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.slate200,
                                child: Text(
                                  initial,
                                  style: const TextStyle(color: AppColors.slate700),
                                ),
                              ),
                              title: Text(contact.displayName),
                              subtitle: Text(phone),
                              onTap: () {
                                Navigator.pop(ctx);
                                context.go('/payment', extra: {
                                  'phone': phone,
                                  'name': contact.displayName,
                                });
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Removed _showUpiIdInput as it's redundant. Use context.push('/payment') directly.

  void _showSOSDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Emergency SOS'),
          ],
        ),
        content: const Text(
          'This will alert your emergency contacts and freeze your account for security. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(accountFreezeProvider.notifier).state = true;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent! Account frozen.'),
                  backgroundColor: AppColors.slate500,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Activate SOS'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slate500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SosButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.sos_rounded, color: Colors.red, size: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              'SOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/entities.dart';

class AlertItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String time;

  const AlertItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class RecentAlertsWidget extends StatelessWidget {
  final List<Alert> alerts;

  const RecentAlertsWidget({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Center(
          child: Text(
            'No recent alerts',
            style: TextStyle(color: AppColors.slate400),
          ),
        ),
      );
    }

    return Column(
      children: alerts.take(2).map((alert) {
        return _AlertCard(alert: alert);
      }).toList(),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBackground) = _getAlertVisuals(alert.severity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            alert.time,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _getAlertVisuals(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return (Icons.error_rounded, AppColors.red500, AppColors.red100);
      case AlertSeverity.high:
        return (Icons.warning_amber_rounded, AppColors.amber500, const Color(0xFFFEF3C7));
      case AlertSeverity.medium:
        return (Icons.info_rounded, Colors.blue, const Color(0xFFDBEAFE));
      case AlertSeverity.low:
        return (Icons.verified_user_rounded, AppColors.emerald500, AppColors.green100);
    }
  }
}

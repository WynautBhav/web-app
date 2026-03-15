import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/entities.dart';

class ThreatCard extends StatelessWidget {
  final Threat threat;
  final VoidCallback? onTap;

  const ThreatCard({super.key, required this.threat, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.05),
        ),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: threat.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(threat.icon, color: threat.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        threat.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      threat.time,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  threat.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSeverityColor(threat.severity).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getSeverityLabel(threat.severity),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getSeverityColor(threat.severity),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.slate300,
            size: 20,
          ),
        ],
      ),
    ),
    );
  }

  Color _getSeverityColor(ThreatSeverity severity) {
    switch (severity) {
      case ThreatSeverity.high:
        return AppColors.slate900;
      case ThreatSeverity.medium:
        return AppColors.slate600;
      case ThreatSeverity.low:
        return AppColors.slate400;
    }
  }

  String _getSeverityLabel(ThreatSeverity severity) {
    switch (severity) {
      case ThreatSeverity.high:
        return 'HIGH';
      case ThreatSeverity.medium:
        return 'MEDIUM';
      case ThreatSeverity.low:
        return 'LOW';
    }
  }
}

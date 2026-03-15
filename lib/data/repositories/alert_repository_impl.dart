import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class AlertRepositoryImpl implements AlertRepository {
  final List<Alert> _alerts = [
    const Alert(
      id: '1',
      title: 'New Login Detected',
      subtitle: 'Chrome on MacOS • Mumbai, India',
      severity: AlertSeverity.medium,
      time: '2 min ago',
    ),
    const Alert(
      id: '2',
      title: 'System Scan Complete',
      subtitle: '0 vulnerabilities found on your device',
      severity: AlertSeverity.low,
      time: '1 hour ago',
    ),
    const Alert(
      id: '3',
      title: 'Unusual Spending Pattern',
      subtitle: 'Large transaction of ₹5,000 detected',
      severity: AlertSeverity.high,
      time: '3 hours ago',
    ),
    const Alert(
      id: '4',
      title: 'Password Strength Improved',
      subtitle: 'Your account password is now stronger',
      severity: AlertSeverity.low,
      time: 'Yesterday',
    ),
    const Alert(
      id: '5',
      title: 'New Device Authorized',
      subtitle: 'OnePlus 12 Pro added to your account',
      severity: AlertSeverity.medium,
      time: 'Yesterday',
    ),
    const Alert(
      id: '6',
      title: 'Suspicious Link Blocked',
      subtitle: 'Malicious URL was blocked before loading',
      severity: AlertSeverity.high,
      time: '2 days ago',
    ),
    const Alert(
      id: '7',
      title: 'Biometric Login Enabled',
      subtitle: 'Fingerprint authentication is now active',
      severity: AlertSeverity.low,
      time: '3 days ago',
    ),
    const Alert(
      id: '8',
      title: 'Transaction Alert',
      subtitle: 'UPI payment of ₹250 to Swiggy',
      severity: AlertSeverity.low,
      time: '3 days ago',
    ),
  ];

  @override
  Future<List<Alert>> getAlerts() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _alerts;
  }

  @override
  Future<void> markAsRead(String alertId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

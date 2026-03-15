import '../entities/entities.dart';

abstract class AlertRepository {
  Future<List<Alert>> getAlerts();
  Future<void> markAsRead(String alertId);
  Future<void> markAllAsRead();
}

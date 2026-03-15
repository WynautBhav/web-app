enum AlertSeverity { low, medium, high, critical }

class Alert {
  final String id;
  final String title;
  final String subtitle;
  final AlertSeverity severity;
  final String time;
  final bool isRead;

  const Alert({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.time,
    this.isRead = false,
  });

  Alert copyWith({bool? isRead}) {
    return Alert(
      id: id,
      title: title,
      subtitle: subtitle,
      severity: severity,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}

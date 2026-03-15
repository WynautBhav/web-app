import 'package:flutter/material.dart';

enum ThreatType { phishing, scamCall, fakeWebsite, suspiciousLink }

enum ThreatSeverity { low, medium, high }

class Threat {
  final String id;
  final String title;
  final String description;
  final ThreatType type;
  final ThreatSeverity severity;
  final String time;
  final String location;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double latitude;
  final double longitude;

  const Threat({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.time,
    required this.location,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });
}

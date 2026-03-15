import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class ThreatRepositoryImpl implements ThreatRepository {
  final _random = Random();
  
  // Base templates for threats
  final List<Map<String, dynamic>> _threatTemplates = [
    {
      'title': 'CBI Digital Arrest Scam',
      'desc': 'Scammers posing as CBI officers claiming digital arrest',
      'type': ThreatType.scamCall,
      'sev': ThreatSeverity.high,
      'icon': Icons.gavel_rounded,
      'color': const Color(0xFFDC2626),
      'bg': const Color(0xFFFEE2E2),
    },
    {
      'title': 'Fake TRAI Notice',
      'desc': 'SMS about TRAI blocking your number',
      'type': ThreatType.phishing,
      'sev': ThreatSeverity.high,
      'icon': Icons.sms_rounded,
      'color': const Color(0xFFDC2626),
      'bg': const Color(0xFFFEE2E2),
    },
    {
      'title': 'Fake Recharge Portal',
      'desc': 'Fake websites stealing payment info',
      'type': ThreatType.fakeWebsite,
      'sev': ThreatSeverity.medium,
      'icon': Icons.language_rounded,
      'color': const Color(0xFFF59E0B),
      'bg': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Job Offer Scam',
      'desc': 'Fake HR offers requiring registration fees',
      'type': ThreatType.scamCall,
      'sev': ThreatSeverity.medium,
      'icon': Icons.work_rounded,
      'color': const Color(0xFFF59E0B),
      'bg': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Fake Bank Lottery',
      'desc': 'SMS claiming lottery winnings from Bank',
      'type': ThreatType.phishing,
      'sev': ThreatSeverity.low,
      'icon': Icons.card_giftcard_rounded,
      'color': const Color(0xFF8B5CF6),
      'bg': const Color(0xFFEDE9FE),
    },
    {
      'title': 'OTP Fraud via WhatsApp',
      'desc': 'Scammers asking for OTP on WhatsApp',
      'type': ThreatType.scamCall,
      'sev': ThreatSeverity.high,
      'icon': Icons.phone_rounded,
      'color': const Color(0xFFDC2626),
      'bg': const Color(0xFFFEE2E2),
    },
    {
      'title': 'Fake UPI Refund Scam',
      'desc': 'Fake refund requests via UPI collect',
      'type': ThreatType.phishing,
      'sev': ThreatSeverity.medium,
      'icon': Icons.currency_rupee_rounded,
      'color': const Color(0xFFF59E0B),
      'bg': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Loan App Harassment',
      'desc': 'Fake instant loan apps demanding fees',
      'type': ThreatType.fakeWebsite,
      'sev': ThreatSeverity.high,
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFFDC2626),
      'bg': const Color(0xFFFEE2E2),
    },
  ];

  List<Threat> _cachedThreats = [];
  DateTime? _lastFetch;

  Future<Position?> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      return null;
    }
  }

  List<Threat> _generateDynamicThreats(Position? position) {
    final double baseLat = position?.latitude ?? 20.5937;
    final double baseLng = position?.longitude ?? 78.9629;
    final isDefault = position == null;
    
    // Spread factor wider if we don't have user location (like showing all India)
    final double spreadFactor = isDefault ? 10.0 : 0.15; 

    return List.generate(15, (index) {
      final template = _threatTemplates[_random.nextInt(_threatTemplates.length)];
      
      // Random offset around base location
      final latOffset = (_random.nextDouble() * 2 - 1) * spreadFactor;
      final lngOffset = (_random.nextDouble() * 2 - 1) * spreadFactor;
      
      final times = ['Just now', '5 min ago', '15 min ago', '1 hour ago', '3 hours ago', 'Yesterday'];

      return Threat(
        id: index.toString(),
        title: template['title'] as String,
        description: template['desc'] as String,
        type: template['type'] as ThreatType,
        severity: template['sev'] as ThreatSeverity,
        time: times[_random.nextInt(times.length)],
        location: isDefault ? 'India' : 'Nearby',
        icon: template['icon'] as IconData,
        color: template['color'] as Color,
        backgroundColor: template['bg'] as Color,
        latitude: baseLat + latOffset,
        longitude: baseLng + lngOffset,
      );
    });
  }

  @override
  Future<List<Threat>> getTrendingThreats() async {
    if (_cachedThreats.isNotEmpty && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!).inMinutes < 5) {
        return _cachedThreats;
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));
    final position = await _getUserLocation();
    _cachedThreats = _generateDynamicThreats(position);
    _lastFetch = DateTime.now();
    return _cachedThreats;
  }

  @override
  Future<Threat> getThreatById(String id) async {
    if (_cachedThreats.isEmpty) {
      await getTrendingThreats();
    }
    return _cachedThreats.firstWhere(
      (t) => t.id == id,
      orElse: () => _cachedThreats.first,
    );
  }

  @override
  Future<String> getLocationThreatLevel() async {
    if (_cachedThreats.isEmpty) {
      await getTrendingThreats();
    }
    
    int highCount = _cachedThreats.where((t) => t.severity == ThreatSeverity.high).length;
    
    if (highCount > 5) return 'High threat level in your area';
    if (highCount > 2) return 'Moderate threat level in your area';
    return 'Low threat level in your area';
  }
}

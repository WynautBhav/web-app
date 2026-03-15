import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/gemini_service.dart';
import '../../services/anomaly_detector.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final anomalyDetectorProvider = Provider<AnomalyDetector>((ref) {
  return AnomalyDetector();
});

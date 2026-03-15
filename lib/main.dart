import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'app.dart';
import 'services/threat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ThreatService.init();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env file not found — app will use demo mode
  }
  
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        showOnboardingProvider.overrideWith((ref) => !onboardingCompleted),
      ],
      child: const ArgusEyeApp(),
    ),
  );
}

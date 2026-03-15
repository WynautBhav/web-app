import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/radar/presentation/screens/radar_screen.dart';
import '../../features/tools/presentation/screens/tools_screen.dart';
import '../../features/tools/presentation/screens/recipient_check_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/payment/presentation/screens/payment_entry_screen.dart';
import '../../features/payment/presentation/screens/payment_risk_screen.dart';
import '../../features/payment/presentation/screens/payment_safe_screen.dart';
import '../../services/gemini_service.dart';
import '../widgets/main_scaffold.dart';

final showOnboardingProvider = StateProvider<bool>((ref) => true);

/// Check SharedPreferences and initialize the onboarding state
final onboardingCheckProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final completed = prefs.getBool('onboarding_completed') ?? false;
  ref.read(showOnboardingProvider.notifier).state = !completed;
  return completed;
});

final routerProvider = Provider<GoRouter>((ref) {
  final showOnboarding = ref.watch(showOnboardingProvider);
  
  return GoRouter(
    initialLocation: showOnboarding ? '/onboarding' : '/home',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => PaymentEntryScreen(
          initialData: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/payment-risk',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PaymentRiskScreen(
            riskScore: extra['riskScore'] as RiskScore,
            paymentData: extra['paymentData'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '/payment-safe',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return PaymentSafeScreen(data: data);
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const TransactionsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/tools',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ToolsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/recipient-check',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RecipientCheckScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/radar',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RadarScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NotificationsScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          ),
        ],
      ),
    ],
  );
});

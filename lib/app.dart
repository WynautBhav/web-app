import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/locale_provider.dart';
import 'core/widgets/app_lifecycle_wrapper.dart';

class ArgusEyeApp extends ConsumerWidget {
  const ArgusEyeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    
    return AppLifecycleWrapper(
      child: MaterialApp.router(
        title: 'Argus Eye',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: router,
        locale: locale,
        supportedLocales: LocaleNotifier.supportedLocales.values.toList(),
        localeResolutionCallback: (locale, supportedLocales) {
          return locale;
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/lock_screen.dart';

class LifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;

  LifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Lock the app when it goes to the background
      ref.read(isAppLockedProvider.notifier).state = true;
    }
  }
}

class AppLifecycleWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends ConsumerState<AppLifecycleWrapper> {
  late LifecycleObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = LifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(isAppLockedProvider);
    
    // We render the lock screen on top if the app is locked
    return Stack(
      children: [
        widget.child,
        if (isLocked)
          const Positioned.fill(
            child: LockScreen(),
          ),
      ],
    );
  }
}

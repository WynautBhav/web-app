import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../services/biometric_service.dart';

final userProvider = FutureProvider<User>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUser();
});

final securityScoreProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  final user = await repository.getCurrentUser();
  return user.securityScore;
});

final refreshSecurityScoreProvider = FutureProvider.family<int, void>((ref, _) async {
  final repository = ref.watch(userRepositoryProvider);
  final user = await repository.refreshSecurityScore();
  ref.invalidate(userProvider);
  return user.securityScore;
});

final accountFreezeProvider = StateProvider<bool>((ref) => false);

class SettingsState {
  final bool biometricEnabled;
  final bool identityMonitoring;
  final bool isLoading;

  const SettingsState({
    this.biometricEnabled = true,
    this.identityMonitoring = true,
    this.isLoading = false,
  });

  SettingsState copyWith({
    bool? biometricEnabled,
    bool? identityMonitoring,
    bool? isLoading,
  }) {
    return SettingsState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      identityMonitoring: identityMonitoring ?? this.identityMonitoring,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref ref;
  
  SettingsNotifier(this.ref) : super(const SettingsState());

  Future<bool> toggleBiometric(bool value) async {
    state = state.copyWith(isLoading: true);
    try {
      final biometricService = BiometricService();
      
      final isAvailable = await biometricService.isBiometricAvailable();
      if (!isAvailable && value) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      if (value) {
        final authenticated = await biometricService.authenticateForSettingChange(true);
        if (!authenticated) {
          state = state.copyWith(isLoading: false);
          return false;
        }
      } else {
        final authenticated = await biometricService.authenticateForSettingChange(false);
        if (!authenticated) {
          state = state.copyWith(isLoading: false);
          return false;
        }
      }
      
      await ref.read(userRepositoryProvider).updateBiometricSetting(value);
      state = state.copyWith(biometricEnabled: value, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> toggleIdentityMonitoring(bool value) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(userRepositoryProvider).updateIdentityMonitoring(value);
      state = state.copyWith(identityMonitoring: value, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});

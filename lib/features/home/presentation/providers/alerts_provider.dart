import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../core/di/repository_providers.dart';

final alertsProvider = FutureProvider<List<Alert>>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getAlerts();
});

final alertsRefreshProvider = FutureProvider.family<List<Alert>, void>((ref, _) async {
  final repository = ref.watch(alertRepositoryProvider);
  ref.invalidate(alertsProvider);
  return repository.getAlerts();
});

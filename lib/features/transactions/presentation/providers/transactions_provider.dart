import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/entities.dart';
import '../../../../core/di/repository_providers.dart';

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final statusFilterProvider = StateProvider<String>((ref) => 'All');

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(selectedCategoryProvider);
  return repository.getTransactions(filter: filter);
});

final transactionsRefreshProvider = FutureProvider.family<List<Transaction>, void>((ref, _) async {
  final repository = ref.watch(transactionRepositoryProvider);
  final filter = ref.watch(selectedCategoryProvider);
  ref.invalidate(transactionsProvider);
  return repository.getTransactions(filter: filter);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/repositories.dart';
import '../../data/repositories/repositories_impl.dart';

// Singleton instances so in-memory caches survive provider re-reads
final _userRepo = UserRepositoryImpl();
final _transactionRepo = TransactionRepositoryImpl();
final _alertRepo = AlertRepositoryImpl();
final _threatRepo = ThreatRepositoryImpl();

final userRepositoryProvider = Provider<UserRepository>((ref) => _userRepo);
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) => _transactionRepo);
final alertRepositoryProvider = Provider<AlertRepository>((ref) => _alertRepo);
final threatRepositoryProvider = Provider<ThreatRepository>((ref) => _threatRepo);

import '../entities/entities.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({String? filter});
  Future<Transaction> getTransactionById(String id);
}

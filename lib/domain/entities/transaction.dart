enum TransactionStatus { safe, suspicious, blocked }

enum TransactionType { expense, income, refund }

class Transaction {
  final String id;
  final String name;
  final String? merchantLogoUrl;
  final double amount;
  final String category;
  final String time;
  final TransactionStatus status;
  final TransactionType type;

  const Transaction({
    required this.id,
    required this.name,
    this.merchantLogoUrl,
    required this.amount,
    required this.category,
    required this.time,
    required this.status,
    required this.type,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isBlocked => status == TransactionStatus.blocked;
}

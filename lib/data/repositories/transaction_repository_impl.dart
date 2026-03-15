import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final List<Transaction> _transactions = [
    const Transaction(
      id: '1',
      name: 'Reliance Digital',
      merchantLogoUrl: '',
      amount: 1299.00,
      category: 'Electronics',
      time: '14:20',
      status: TransactionStatus.safe,
      type: TransactionType.expense,
    ),
    const Transaction(
      id: '2',
      name: 'Swiggy',
      merchantLogoUrl: '',
      amount: 450.00,
      category: 'Food',
      time: '09:15',
      status: TransactionStatus.safe,
      type: TransactionType.expense,
    ),
    const Transaction(
      id: '3',
      name: 'Unknown UPI Transfer',
      merchantLogoUrl: '',
      amount: 5000.00,
      category: 'Pending Review',
      time: '22:10',
      status: TransactionStatus.suspicious,
      type: TransactionType.expense,
    ),
    const Transaction(
      id: '4',
      name: 'Myntra',
      merchantLogoUrl: '',
      amount: 2499.00,
      category: 'Shopping',
      time: '18:45',
      status: TransactionStatus.blocked,
      type: TransactionType.expense,
    ),
    const Transaction(
      id: '5',
      name: 'Salary Deposit',
      merchantLogoUrl: '',
      amount: 45000.00,
      category: 'Income',
      time: '08:00',
      status: TransactionStatus.safe,
      type: TransactionType.income,
    ),
    const Transaction(
      id: '6',
      name: 'PhonePe Transfer',
      merchantLogoUrl: '',
      amount: 250.00,
      category: 'Transfer',
      time: '11:30',
      status: TransactionStatus.safe,
      type: TransactionType.expense,
    ),
    const Transaction(
      id: '7',
      name: 'suspicious@upi',
      merchantLogoUrl: '',
      amount: 45000.00,
      category: 'Unknown',
      time: '15:00',
      status: TransactionStatus.suspicious,
      type: TransactionType.expense,
    ),
  ];

  @override
  Future<List<Transaction>> getTransactions({String? filter}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (filter == null || filter == 'All') {
      return _transactions;
    }
    
    return _transactions.where((t) {
      switch (filter) {
        case 'Spending':
          return t.type == TransactionType.expense;
        case 'Income':
          return t.type == TransactionType.income;
        case 'Refunds':
          return t.type == TransactionType.refund;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Future<Transaction> getTransactionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _transactions.firstWhere((t) => t.id == id);
  }
}

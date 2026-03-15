import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../domain/entities/transaction.dart';
import '../providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildCategoryFilter(ref, selectedCategory),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(transactionsProvider);
                },
                child: transactionsAsync.when(
                  data: (transactions) => _buildTransactionsList(transactions),
                  loading: () => const ListShimmer(itemCount: 5),
                  error: (error, _) => ErrorStateWidget(
                    title: 'Failed to load transactions',
                    message: 'Pull down to refresh',
                    onRetry: () => ref.invalidate(transactionsProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          const Text(
            'Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showFilterSheet(context),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Icon(
                    Icons.filter_list_rounded,
                    color: AppColors.slate600,
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showSearch(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.slate600,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSearch(BuildContext context) async {
    final transactions = ref.read(transactionsProvider).valueOrNull ?? [];
    await showSearch(
      context: context,
      delegate: _TransactionSearchDelegate(transactions),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final filters = ['All', 'Safe', 'Suspicious', 'Blocked'];
    final current = ref.read(statusFilterProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          String selected = current;
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Filter by Status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filters.map((filter) {
                    final isSelected = selected == filter;
                    return GestureDetector(
                      onTap: () => setModalState(() => selected = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.slate100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.slate600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() => selected = 'All');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(statusFilterProvider.notifier).state = selected;
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter(WidgetRef ref, String selectedCategory) {
    final categories = ['All', 'Spending', 'Income', 'Refunds'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;
          return GestureDetector(
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = category;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.slate600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    final statusFilter = ref.read(statusFilterProvider);
    var filtered = transactions;

    if (statusFilter != 'All') {
      filtered = transactions.where((t) {
        switch (statusFilter) {
          case 'Safe':
            return t.status == TransactionStatus.safe;
          case 'Suspicious':
            return t.status == TransactionStatus.suspicious;
          case 'Blocked':
            return t.status == TransactionStatus.blocked;
          default:
            return true;
        }
      }).toList();
    }

    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        title: 'No transactions',
        message: 'No transactions match the selected filter',
        icon: Icons.receipt_long_rounded,
      );
    }

    // Group by time label: transactions with 'ago' or ':' in their time field = today, else = earlier
    final todayTransactions = filtered.where((t) =>
      t.time.contains('ago') || t.time.contains(':')
    ).toList();
    final earlierTransactions = filtered.where((t) =>
      !t.time.contains('ago') && !t.time.contains(':')
    ).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (todayTransactions.isNotEmpty) ...[
            _buildSection('Today', todayTransactions),
            const SizedBox(height: 24),
          ],
          if (earlierTransactions.isNotEmpty)
            _buildSection('Earlier', earlierTransactions),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.slate400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...transactions.map((t) => TransactionCard(transaction: t)),
      ],
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isBlocked = transaction.status == TransactionStatus.blocked;
    final isSuspicious = transaction.status == TransactionStatus.suspicious;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: transaction.merchantLogoUrl != null && transaction.merchantLogoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      transaction.merchantLogoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: AppColors.slate400,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isBlocked ? AppColors.slate400 : AppColors.slate900,
                    decoration: isBlocked ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildStatusBadge(),
                    const SizedBox(width: 8),
                    Text(
                      transaction.time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.isExpense
                    ? '-₹${transaction.amount.toStringAsFixed(2)}'
                    : '+₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: transaction.isExpense
                      ? (isBlocked ? AppColors.slate400 : AppColors.slate900)
                      : AppColors.slate800,
                  decoration: isBlocked ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.category,
                style: TextStyle(
                  fontSize: 12,
                  color: isBlocked ? AppColors.slate300 : AppColors.slate400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    Color dotColor;
    String text;

    switch (transaction.status) {
      case TransactionStatus.safe:
        backgroundColor = AppColors.slate100;
        textColor = AppColors.slate900;
        dotColor = AppColors.slate900;
        text = 'Safe';
        break;
      case TransactionStatus.suspicious:
        backgroundColor = AppColors.slate200;
        textColor = AppColors.slate700;
        dotColor = AppColors.slate600;
        text = 'Suspicious';
        break;
      case TransactionStatus.blocked:
        backgroundColor = AppColors.slate300;
        textColor = AppColors.slate500;
        dotColor = AppColors.slate400;
        text = 'Blocked';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionSearchDelegate extends SearchDelegate<Transaction?> {
  final List<Transaction> transactions;

  _TransactionSearchDelegate(this.transactions);

  @override
  String get searchFieldLabel => 'Search transactions...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.slate900,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.slate400),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = transactions.where((t) =>
      t.name.toLowerCase().contains(query.toLowerCase()) ||
      t.category.toLowerCase().contains(query.toLowerCase()) ||
      t.amount.toString().contains(query)
    ).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            Text(
              'No transactions found for "$query"',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.slate400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return TransactionCard(transaction: results[index]);
      },
    );
  }
}

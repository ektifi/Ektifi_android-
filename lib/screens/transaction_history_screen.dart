import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

enum TransactionStatus {
  successful,
  pending,
  failed,
  refunded,
}

enum PaymentMethod {
  creditCard,
  debitCard,
  bankTransfer,
  wallet,
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedStatus;

  // Status filter options
  final List<String> _statusOptions = [
    'all',
    'successful',
    'pending',
    'failed',
    'refunded',
  ];

  // Sample transaction data
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TXN-2024-001',
      'institutionName': 'Al-Faisal International School',
      'amount': 500.00,
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'status': TransactionStatus.successful,
      'paymentMethod': PaymentMethod.creditCard,
    },
    {
      'id': 'TXN-2024-002',
      'institutionName': 'King Saud University',
      'amount': 750.00,
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'status': TransactionStatus.successful,
      'paymentMethod': PaymentMethod.debitCard,
    },
    {
      'id': 'TXN-2024-003',
      'institutionName': 'British International School',
      'amount': 600.00,
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'status': TransactionStatus.pending,
      'paymentMethod': PaymentMethod.bankTransfer,
    },
    {
      'id': 'TXN-2024-004',
      'institutionName': 'King Fahd University of Petroleum & Minerals',
      'amount': 800.00,
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'status': TransactionStatus.successful,
      'paymentMethod': PaymentMethod.wallet,
    },
    {
      'id': 'TXN-2024-005',
      'institutionName': 'Riyadh Schools',
      'amount': 450.00,
      'date': DateTime.now().subtract(const Duration(days: 12)),
      'status': TransactionStatus.failed,
      'paymentMethod': PaymentMethod.creditCard,
    },
    {
      'id': 'TXN-2024-006',
      'institutionName': 'Princess Nourah bint Abdulrahman University',
      'amount': 700.00,
      'date': DateTime.now().subtract(const Duration(days: 15)),
      'status': TransactionStatus.successful,
      'paymentMethod': PaymentMethod.creditCard,
    },
    {
      'id': 'TXN-2024-007',
      'institutionName': 'Al-Noor Girls School',
      'amount': 550.00,
      'date': DateTime.now().subtract(const Duration(days: 18)),
      'status': TransactionStatus.refunded,
      'paymentMethod': PaymentMethod.debitCard,
    },
    {
      'id': 'TXN-2024-008',
      'institutionName': 'King Abdulaziz University',
      'amount': 900.00,
      'date': DateTime.now().subtract(const Duration(days: 20)),
      'status': TransactionStatus.successful,
      'paymentMethod': PaymentMethod.bankTransfer,
    },
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((transaction) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final institutionName = transaction['institutionName'] as String;
        final transactionId = transaction['id'] as String;
        if (!institutionName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !transactionId.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // Filter by status
      if (_selectedStatus != null && _selectedStatus != 'all') {
        final status = transaction['status'] as TransactionStatus;
        String statusKey = '';
        switch (status) {
          case TransactionStatus.successful:
            statusKey = 'successful';
            break;
          case TransactionStatus.pending:
            statusKey = 'pending';
            break;
          case TransactionStatus.failed:
            statusKey = 'failed';
            break;
          case TransactionStatus.refunded:
            statusKey = 'refunded';
            break;
        }
        if (statusKey != _selectedStatus) return false;
      }

      return true;
    }).toList();
  }

  String _getNameKey(String name) {
    return name.toLowerCase().replaceAll(' ', '_').replaceAll('&', '').replaceAll(',', '').replaceAll("'", '');
  }

  String _getDisplayName(String name, AppLocalizations? localizations) {
    if (localizations == null) return name;
    
    final key = _getNameKey(name);
    final translated = localizations.translate(key);
    
    // If translation returns the same key, it means translation doesn't exist, use original name
    if (translated == key) {
      return name;
    }
    
    return translated;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildStatusText(TransactionStatus status, AppLocalizations? localizations) {
    String statusKey = '';
    Color statusColor = Colors.grey;

    switch (status) {
      case TransactionStatus.successful:
        statusKey = 'successful';
        statusColor = Colors.green;
        break;
      case TransactionStatus.pending:
        statusKey = 'pending';
        statusColor = Colors.orange;
        break;
      case TransactionStatus.failed:
        statusKey = 'failed';
        statusColor = Colors.red;
        break;
      case TransactionStatus.refunded:
        statusKey = 'refunded';
        statusColor = Colors.blue;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == TransactionStatus.failed)
          Icon(
            Icons.error,
            size: 14,
            color: statusColor,
          ),
        if (status == TransactionStatus.failed) const SizedBox(width: 4),
        Text(
          '${localizations?.translate(statusKey) ?? statusKey}${status == TransactionStatus.failed ? '!' : ''}',
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String option, AppLocalizations? localizations) {
    final isSelected = _selectedStatus == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = isSelected ? null : option;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.accentCyan, AppTheme.primaryIndigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentCyan.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          localizations?.translate(option) ?? option,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    Map<String, dynamic> transaction,
    AppLocalizations? localizations,
  ) {
    final institutionName = transaction['institutionName'] as String;
    final amount = transaction['amount'] as double;
    final date = transaction['date'] as DateTime;
    final status = transaction['status'] as TransactionStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // Institution Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentCyan.withOpacity(0.2),
                    AppTheme.primaryIndigo.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/ektifi-logo copy.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Institution Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDisplayName(institutionName, localizations),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Amount and Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusText(status, localizations),
                  Text(
                    '${amount.toStringAsFixed(2)} ${localizations?.translate('sar') ?? 'SAR'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          localizations?.translate('transaction_history') ?? 'Transaction History',
          style: const TextStyle(
            color: AppTheme.primaryIndigo,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _filteredTransactions.isEmpty
          ? Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: localizations?.translate('search_colleges_schools') ?? 'Search colleges or schools',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.accentCyan),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                // Status Filters
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  color: Colors.white,
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('all', localizations),
                        ..._statusOptions.where((option) => option != 'all').map(
                          (option) => _buildFilterChip(option, localizations),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations?.translate('no_transactions') ?? 'No transactions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : CustomScrollView(
              slivers: [
                // Search Bar
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    color: Colors.white,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: localizations?.translate('search_colleges_schools') ?? 'Search colleges or schools',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.accentCyan),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                // Status Filters
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    color: Colors.white,
                    child: SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('all', localizations),
                          ..._statusOptions.where((option) => option != 'all').map(
                            (option) => _buildFilterChip(option, localizations),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Transactions List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildTransactionCard(
                          context,
                          _filteredTransactions[index],
                          localizations,
                        );
                      },
                      childCount: _filteredTransactions.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}


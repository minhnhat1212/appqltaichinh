import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';
import '../theme.dart';
import '../widgets/transaction_card.dart';
import '../widgets/shimmer_loading.dart';
import 'add_transaction_screen.dart';
import '../utils/page_transitions.dart';

/// Màn hình danh sách giao dịch
/// Hiển thị danh sách tất cả giao dịch của người dùng với khả năng thêm mới
class TransactionListScreen extends StatefulWidget {
  final String userId;

  const TransactionListScreen({super.key, required this.userId});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  late Stream<List<TransactionModel>> _transactionStream;
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _transactionStream = _transactionService.getTransactions(widget.userId);
  }

  @override
  void didUpdateWidget(TransactionListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _transactionStream = _transactionService.getTransactions(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.only(top: AppTheme.spacing, bottom: 80),
              itemCount: 5,
              itemBuilder: (context, index) => const TransactionCardShimmer(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: AppColors.error),
                  const SizedBox(height: AppTheme.spacing),
                  Text(
                    'Lỗi: ${snapshot.error}',
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyTransactionState();
          }

          final transactions = snapshot.data!;

          final groupedTransactions = _groupTransactionsByDate(transactions);

          return RefreshIndicator(
            onRefresh: () async {
              // Just wait a bit - the stream will auto-refresh
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppTheme.spacing,
                bottom: 80, // Space for FAB
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: groupedTransactions.length,
              itemBuilder: (context, groupIndex) {
                final dateKey = groupedTransactions.keys.elementAt(groupIndex);
                final dayTransactions = groupedTransactions[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: AppTheme.animationDuration,
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing,
                              vertical: AppTheme.spacingSmall,
                            ),
                            child: Text(
                              dateKey,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Transactions for this date with staggered animation
                    ...dayTransactions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final transaction = entry.value;
                      return TransactionCard(
                        transaction: transaction,
                        categoryName: 'Danh mục', // TODO: Get from category
                        index: index,
                        onTap: () {
                          Navigator.of(context).push(
                            SlideAndFadePageRoute(
                              page: AddTransactionScreen(
                                transaction: transaction,
                              ),
                            ),
                          );
                        },
                      );
                    }),

                    const SizedBox(height: AppTheme.spacingSmall),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _AnimatedFAB(
        onPressed: () {
          Navigator.of(
            context,
          ).push(ScalePageRoute(page: const AddTransactionScreen()));
        },
      ),
    );
  }

  // Helper method để gom nhóm giao dịch
  Map<String, List<TransactionModel>> _groupTransactionsByDate(
    List<TransactionModel> transactions,
  ) {
    // Gom nhóm giao dịch theo Ngày (Date Grouping)
    // Map<String, List<TransactionModel>>: Key là chuỗi ngày hiển thị, Value là list transaction
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groupedTransactions = <String, List<TransactionModel>>{};

    for (var transaction in transactions) {
      final dateKey = _formatDateKey(transaction.date, today);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }
    return groupedTransactions;
  }

  // Helper format ngày để hiển thị header: "Hôm nay", "Hôm qua", hoặc "dd/MM/yyyy"
  String _formatDateKey(DateTime date, DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Hôm nay';
    } else if (dateOnly == yesterday) {
      return 'Hôm qua';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Animated FAB that scales when scrolling
class _AnimatedFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedFAB({required this.onPressed});

  @override
  State<_AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<_AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.animationDuration,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: RotationTransition(
        turns: _rotationAnimation,
        child: FloatingActionButton.extended(
          onPressed: widget.onPressed,
          icon: const Icon(Icons.add),
          label: const Text('Giao dịch'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

/// Balance Summary Card with Enhanced Glassmorphism
class BalanceSummaryCard extends StatefulWidget {
  final String userId;

  const BalanceSummaryCard({super.key, required this.userId});

  @override
  State<BalanceSummaryCard> createState() => _BalanceSummaryCardState();
}

class _BalanceSummaryCardState extends State<BalanceSummaryCard> {
  late Stream<Map<String, double>> _balanceStream;

  @override
  void initState() {
    super.initState();
    _balanceStream = _getBalanceSummary();
  }

  @override
  void didUpdateWidget(BalanceSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _balanceStream = _getBalanceSummary();
    }
  }

  Stream<Map<String, double>> _getBalanceSummary() {
    final walletService = WalletService(); // Service để lấy dữ liệu ví
    final transactionService =
        TransactionService(); // Service để lấy dữ liệu giao dịch

    // ✅ Optimized: Calculate total balance from wallets (much faster)
    // and income/expense from current month transactions only
    final now = DateTime.now(); // Thời gian hiện tại
    final monthStart = DateTime(
      now.year,
      now.month,
      1,
    ); // Ngày đầu tháng (ví dụ: 1/12/2024)
    final monthEnd = DateTime(
      now.year,
      now.month + 1,
      1,
    ); // Ngày đầu tháng sau (ví dụ: 1/1/2025)

    final controller = StreamController<Map<String, double>>();
    StreamSubscription? walletsSub;
    StreamSubscription? transactionsSub;

    List<WalletModel> wallets = [];
    List<TransactionModel> monthTransactions = [];
    bool walletsReady = false;
    bool transactionsReady = false;

    void emitIfReady() {
      if (walletsReady && transactionsReady) {
        // Chỉ tính toán khi đã có đủ dữ liệu từ cả 2 stream
        // Calculate total balance from all wallets - Tính tổng số dư từ tất cả các ví
        double totalBalance = wallets.fold(
          0.0,
          (sum, wallet) => sum + wallet.balance,
        ); // Cộng dồn balance của tất cả ví

        // Calculate income/expense from current month transactions only - Chỉ tính thu/chi từ giao dịch trong tháng hiện tại
        double totalIncome = 0.0; // Tổng thu nhập
        double totalExpense = 0.0; // Tổng chi tiêu

        for (var transaction in monthTransactions) {
          if (transaction.type == 'income') {
            totalIncome +=
                transaction.amount; // Cộng vào thu nhập nếu là giao dịch thu
          } else {
            totalExpense +=
                transaction.amount; // Cộng vào chi tiêu nếu là giao dịch chi
          }
        }

        controller.add({
          'total': totalBalance, // Tổng số dư
          'income': totalIncome, // Tổng thu nhập tháng này
          'expense': totalExpense, // Tổng chi tiêu tháng này
        });
      }
    }

    walletsSub = walletService
        .getWallets(widget.userId)
        .listen(
          (w) {
            wallets = w;
            walletsReady = true;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () {},
        );

    transactionsSub = transactionService
        .getTransactionsForPeriod(widget.userId, monthStart, monthEnd)
        .listen(
          (t) {
            monthTransactions = t;
            transactionsReady = true;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () {},
        );

    controller.onCancel = () {
      walletsSub?.cancel();
      transactionsSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: _balanceStream,
      builder: (context, snapshot) {
        final totalBalance = snapshot.data?['total'] ?? 0.0;
        final totalIncome = snapshot.data?['income'] ?? 0.0;
        final totalExpense = snapshot.data?['expense'] ?? 0.0;

        return FadeInWidget(
          duration: AppTheme.animationDurationSlow,
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spacing),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusXLarge),
              child: Stack(
                children: [
                  // Animated gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.glassmorphicGradientStrong,
                      ),
                    ),
                  ),

                  // Shimmer effect overlay
                  Positioned.fill(child: _ShimmerOverlay()),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng số dư',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusSmall,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'VNĐ',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),

                        // Amount with animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: totalBalance),
                          duration: AppTheme.animationDurationSlow,
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    NumberFormat('#,###').format(value),
                                    style: AppTextStyles.amountLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      'đ',
                                      style: AppTextStyles.h3.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),

                        // Income and Expense Row
                        Row(
                          children: [
                            // Income
                            Expanded(
                              child: _StatItem(
                                icon: Icons.trending_up,
                                label: 'Thu nhập',
                                amount: totalIncome,
                                color: AppColors.income,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing),
                            // Expense
                            Expanded(
                              child: _StatItem(
                                icon: Icons.trending_down,
                                label: 'Chi tiêu',
                                amount: totalExpense,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer Overlay for glass effect
class _ShimmerOverlay extends StatefulWidget {
  @override
  State<_ShimmerOverlay> createState() => _ShimmerOverlayState();
}

class _ShimmerOverlayState extends State<_ShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.0),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Stat Item Widget with enhanced design
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusSmall,
                  ),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: amount),
            duration: AppTheme.animationDurationSlow,
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    NumberFormat('#,###').format(value),
                    style: AppTextStyles.amountMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'đ',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

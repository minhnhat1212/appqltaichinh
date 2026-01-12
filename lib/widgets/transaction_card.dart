import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../models/transaction_model.dart';

/// Transaction Card Widget
/// Hiển thị transaction với design đẹp, color coding, và enhanced animations
class TransactionCard extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final String categoryName;
  final int index;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.categoryName = '',
    this.index = 0,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard>
    with SingleTickerProviderStateMixin {
  static final _currencyFormatter = NumberFormat('#,###');
  static final _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, // Cần để đồng bộ với frame rate
      duration: AppTheme.animationDuration, // Thời gian animation
    );

    _fadeAnimation =
        Tween<double>(
          begin: 0.0, // Bắt đầu với opacity 0 (trong suốt)
          end: 1.0, // Kết thúc với opacity 1 (hiển thị đầy đủ)
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        ); // Đường cong easeOut (giảm tốc dần)

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(
            0,
            0.3,
          ), // Bắt đầu từ vị trí lệch xuống dưới 30% chiều cao
          end: Offset.zero, // Kết thúc ở vị trí gốc
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        ); // Đường cong easeOutCubic (mượt hơn)

    // Staggered animation based on index - Animation lệch thời gian dựa trên index
    Future.delayed(AppTheme.staggerDelayFast * widget.index, () {
      // Delay tăng dần theo index để tạo hiệu ứng lần lượt
      if (mounted)
        _controller.forward(); // Bắt đầu animation nếu widget còn tồn tại
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense =
        widget.transaction.type == 'expense'; // Kiểm tra có phải chi tiêu không
    final color = isExpense
        ? AppColors.expense
        : AppColors.income; // Màu đỏ nếu chi tiêu, xanh nếu thu nhập
    final gradient = isExpense
        ? AppColors
              .expenseGradient // Gradient đỏ cho chi tiêu
        : AppColors.incomeGradient; // Gradient xanh cho thu nhập
    final icon = isExpense
        ? Icons.arrow_downward
        : Icons
              .arrow_upward; // Icon mũi tên xuống cho chi tiêu, lên cho thu nhập

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedScale(
          scale: _isPressed
              ? 0.98
              : 1.0, // Thu nhỏ 2% khi được nhấn (hiệu ứng press)
          duration: AppTheme.animationDurationFast, // Thời gian animation nhanh
          curve: Curves.easeInOut, // Đường cong easeInOut
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing, // Margin ngang theo theme
              vertical: AppTheme.spacingXSmall, // Margin dọc nhỏ
            ),
            decoration: BoxDecoration(
              color: AppColors.surface, // Màu nền surface
              borderRadius: BorderRadius.circular(
                AppTheme.borderRadius,
              ), // Bo góc
              boxShadow: _isPressed
                  ? AppTheme
                        .shadowSmall // Shadow nhỏ khi được nhấn
                  : AppTheme.shadowMedium, // Shadow vừa khi không nhấn
            ),
            child: Material(
              color: Colors
                  .transparent, // Material trong suốt để InkWell hoạt động
              child: InkWell(
                onTap: widget.onTap, // Callback khi tap
                onTapDown: (_) =>
                    setState(() => _isPressed = true), // Bắt đầu nhấn
                onTapUp: (_) =>
                    setState(() => _isPressed = false), // Kết thúc nhấn
                onTapCancel: () =>
                    setState(() => _isPressed = false), // Hủy nhấn
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing),
                  child: Row(
                    children: [
                      // Icon Container với improved styling
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Subtle shine effect
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusSmall,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Icon(icon, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing),

                      // Transaction Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category/Note
                            Text(
                              widget.transaction.note?.isNotEmpty == true
                                  ? widget.transaction.note!
                                  : widget.categoryName.isNotEmpty
                                  ? widget.categoryName
                                  : 'Giao dịch',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // Date with improved styling
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.textSecondary.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _dateFormatter.format(
                                    widget.transaction.date,
                                  ),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppTheme.spacingSmall),

                      // Amount section với improved styling
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall,
                              ),
                              border: Border.all(
                                color: color.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpense
                                      ? Icons.remove_circle_outline
                                      : Icons.add_circle_outline,
                                  size: 14,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isExpense ? '' : '+'}${_currencyFormatter.format(widget.transaction.amount)}',
                                  style: AppTextStyles.amountMedium.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'đ',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty State Widget cho khi chưa có transaction
class EmptyTransactionState extends StatelessWidget {
  const EmptyTransactionState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AppTheme.animationDurationSlow,
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      AppTheme.glowEffect(AppColors.primary, opacity: 0.4),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Shine effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.receipt_long,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AppTheme.animationDurationSlow,
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Column(
                  children: [
                    Text(
                      'Chưa có giao dịch nào',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Nhấn nút + để thêm giao dịch mới',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

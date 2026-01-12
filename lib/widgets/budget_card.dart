import 'package:flutter/material.dart';
import '../models/budget_model.dart';
import '../utils/budget_utils.dart';
import '../theme.dart';

/// Widget hiển thị card ngân sách với thông tin chi tiết
/// Bao gồm tên, chu kỳ, tiến độ, số tiền đã dùng, và số tiền còn lại
/// Có animation pulse khi ngân sách sắp vượt hoặc đã vượt
class BudgetCard extends StatefulWidget {
  final BudgetModel budget;
  final double spentAmount;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.spentAmount,
    this.onTap,
  });

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, // Cần để đồng bộ với frame rate
      duration: const Duration(milliseconds: 1500), // Thời gian một chu kỳ pulse 1.5 giây
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      // Animation từ kích thước bình thường đến phóng to 3%
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut), // Đường cong easeInOut (mượt)
    );

    // Kích hoạt animation pulse cho các trạng thái cảnh báo (warning/danger/exceeded)
    final alertLevel = widget.budget.getAlertLevel(widget.spentAmount); // Lấy mức độ cảnh báo: 'safe', 'warning', 'danger', 'exceeded'
    if (alertLevel == 'warning' ||
        alertLevel == 'danger' ||
        alertLevel == 'exceeded') {
      _pulseController.repeat(reverse: true); // Lặp lại animation pulse (phóng to thu nhỏ liên tục) để thu hút sự chú ý
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.budget.getProgressPercentage(widget.spentAmount); // Phần trăm đã chi (0-100%, có thể >100% nếu vượt)
    final remaining = widget.budget.getRemainingAmount(widget.spentAmount); // Số tiền còn lại (âm nếu vượt ngân sách)
    final alertLevel = widget.budget.getAlertLevel(widget.spentAmount); // Mức độ cảnh báo: 'safe', 'warning', 'danger', 'exceeded'
    final gradient = BudgetUtils.getBudgetGradient(alertLevel); // Gradient màu theo alert level (xanh -> vàng -> đỏ)
    final color = BudgetUtils.getBudgetColor(percentage); // Màu sắc theo phần trăm (xanh nếu thấp, đỏ nếu cao)

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing,
            vertical: AppTheme.spacingSmall,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            child: Stack(
              children: [
                // Glassmorphism overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.glassmorphicGradient,
                  ),
                ),

                // Shimmer effect
                _ShimmerEffect(),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Budget name
                          Expanded(
                            child: Text(
                              widget.budget.name,
                              style: AppTextStyles.h3.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Alert badge
                          if (alertLevel != 'safe')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusSmall,
                                ),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    BudgetUtils.getBudgetAlertIcon(alertLevel),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    alertLevel == 'exceeded'
                                        ? 'Vượt'
                                        : alertLevel == 'danger'
                                        ? 'Nguy hiểm'
                                        : 'Cảnh báo',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Period
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusXSmall,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              BudgetUtils.formatBudgetPeriod(widget.budget),
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Progress bar with gradient
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tiến độ',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadiusXSmall,
                                  ),
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusSmall,
                            ),
                            child: SizedBox(
                              height: 10,
                              child: Stack(
                                children: [
                                  // Background
                                  Container(
                                    color: Colors.white.withOpacity(0.25),
                                  ),

                                  // Progress
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 0.0,
                                      end: (percentage / 100).clamp(0.0, 1.0),
                                    ),
                                    duration: AppTheme.animationDurationSlow,
                                    curve: Curves.easeOut,
                                    builder: (context, value, child) {
                                      return FractionallySizedBox(
                                        widthFactor: value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white,
                                                Colors.white.withOpacity(0.9),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(
                                                  0.6,
                                                ),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Amount info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Spent / Total
                          Expanded(
                            child: _AmountDisplay(
                              label: 'Đã dùng',
                              amount: widget.spentAmount,
                              subtext:
                                  'của ${BudgetUtils.formatCurrency(widget.budget.amount)}',
                              icon: Icons.shopping_cart_outlined,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Remaining
                          Expanded(
                            child: _AmountDisplay(
                              label: 'Còn lại',
                              amount: remaining.abs(),
                              subtext: remaining >= 0 ? 'khả dụng' : 'vượt mức',
                              icon: Icons.savings_outlined,
                              isNegative: remaining < 0,
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
      ),
    );
  }
}

/// Shimmer Effect Widget
class _ShimmerEffect extends StatefulWidget {
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.0),
                ],
                stops: [
                  _controller.value - 0.3,
                  _controller.value,
                  _controller.value + 0.3,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Amount Display Widget
class _AmountDisplay extends StatelessWidget {
  final String label;
  final double amount;
  final String subtext;
  final IconData icon;
  final bool isNegative;

  const _AmountDisplay({
    required this.label,
    required this.amount,
    required this.subtext,
    required this.icon,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isNegative ? '-' : ''}${BudgetUtils.formatCurrency(amount)}',
            style: AppTextStyles.amountMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

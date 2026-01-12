import 'package:flutter/material.dart';
import '../models/savings_goal_model.dart';
import '../theme.dart';
import 'package:intl/intl.dart';

/// Widget hiển thị card mục tiêu tiết kiệm
/// Bao gồm thông tin tiến độ, số tiền đã tiết kiệm, mục tiêu, và deadline
class SavingsGoalCard extends StatelessWidget {
  final SavingsGoalModel goal;
  final VoidCallback? onTap;

  const SavingsGoalCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = goal.getProgressPercentage(); // Phần trăm tiến độ đã đạt được (0-100)
    final status = goal.getStatus(); // Trạng thái: 'completed', 'overdue', 'on_track', 'behind'
    final daysRemaining = goal.getDaysRemaining(); // Số ngày còn lại đến deadline (âm nếu quá hạn)
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫'); // Format tiền tệ VNĐ

    // Chuyển đổi màu sắc từ chuỗi hex sang Color object
    Color goalColor;
    try {
      goalColor = Color(int.parse('0x${goal.color}')); // Parse chuỗi hex (ví dụ: 'FF5733') thành Color
    } catch (e) {
      goalColor = AppColors.primary; // Sử dụng màu primary mặc định nếu parse lỗi
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardBackground,
              AppColors.cardBackground.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: goalColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background gradient overlay
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        goalColor.withOpacity(0.15),
                        goalColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and status badge
                    Row(
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                goalColor.withOpacity(0.3),
                                goalColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconData(goal.iconName),
                            color: goalColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name and status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal.name,
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _buildStatusBadge(status, daysRemaining),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Amount info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đã tiết kiệm',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(goal.currentAmount),
                              style: AppTextStyles.h3.copyWith(
                                color: goalColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Mục tiêu',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormat.format(goal.targetAmount),
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress bar - Thanh tiến độ
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${progress.toStringAsFixed(1)}%', // Hiển thị phần trăm với 1 chữ số thập phân
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: goalColor, // Màu theo goalColor
                                fontWeight: FontWeight.bold, // Chữ đậm
                              ),
                            ),
                            if (!goal.isCompleted()) // Chỉ hiển thị số tiền còn lại nếu chưa hoàn thành
                              Text(
                                'Còn ${currencyFormat.format(goal.getRemainingAmount())}', // Số tiền còn lại cần tiết kiệm
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary, // Màu text phụ
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8), // Khoảng cách
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10), // Bo góc 10px
                          child: SizedBox(
                            height: 12, // Chiều cao thanh tiến độ 12px
                            child: Stack(
                              children: [
                                // Background - Nền thanh tiến độ
                                Container(
                                  color: AppColors.surface.withOpacity(0.3), // Màu nền nhạt (độ trong suốt 30%)
                                ),
                                // Progress - Phần đã hoàn thành
                                FractionallySizedBox(
                                  widthFactor: (progress / 100).clamp(0.0, 1.0), // Tỉ lệ chiều rộng = progress/100, giới hạn từ 0 đến 1
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          goalColor, // Màu đậm
                                          goalColor.withOpacity(0.7), // Màu nhạt hơn (gradient)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Deadline info
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Hạn: ${DateFormat('dd/MM/yyyy').format(goal.deadline)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                        if (daysRemaining >= 0 && !goal.isCompleted()) ...[
                          const SizedBox(width: 8),
                          Text(
                            '($daysRemaining ngày)',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: daysRemaining <= 7
                                  ? AppColors.warning
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
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
  }

  /// Xây dựng badge hiển thị trạng thái mục tiêu (hoàn thành/quá hạn/đúng hướng/chậm tiến độ)
  Widget _buildStatusBadge(String status, int daysRemaining) {
    String label; // Nhãn hiển thị
    Color color; // Màu sắc badge
    IconData icon; // Icon tương ứng

    switch (status) {
      case 'completed':
        label = 'Hoàn thành';
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'overdue':
        label = 'Quá hạn';
        color = AppColors.error;
        icon = Icons.warning;
        break;
      case 'behind':
        label = 'Chậm tiến độ';
        color = AppColors.warning;
        icon = Icons.trending_down;
        break;
      default: // on_track
        label = 'Đúng hướng';
        color = AppColors.success;
        icon = Icons.trending_up;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Chuyển đổi tên icon (string) sang IconData để hiển thị
  /// Trả về Icons.savings nếu không tìm thấy icon tương ứng
  IconData _getIconData(String iconName) {
    final iconMap = { // Map tên icon sang IconData
      'savings': Icons.savings,
      'car': Icons.directions_car,
      'flight': Icons.flight,
      'home': Icons.home,
      'school': Icons.school,
      'shopping': Icons.shopping_bag,
      'phone': Icons.phone_android,
      'computer': Icons.computer,
      'camera': Icons.camera_alt,
      'gift': Icons.card_giftcard,
      'heart': Icons.favorite,
      'star': Icons.star,
      'wallet': Icons.account_balance_wallet,
      'beach': Icons.beach_access,
      'restaurant': Icons.restaurant,
      'fitness': Icons.fitness_center,
    };

    return iconMap[iconName] ?? Icons.savings;
  }
}

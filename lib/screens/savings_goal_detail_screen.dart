import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';
import '../theme.dart';
import '../widgets/gradient_button.dart';
import 'add_edit_savings_goal_screen.dart';

/// Màn hình chi tiết mục tiêu tiết kiệm
/// Hiển thị tiến độ, số tiền đã góp, lịch sử contributions và cho phép góp thêm/sửa/xóa
class SavingsGoalDetailScreen extends StatefulWidget {
  final SavingsGoalModel goal;

  const SavingsGoalDetailScreen({super.key, required this.goal});

  @override
  State<SavingsGoalDetailScreen> createState() =>
      _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  final SavingsGoalService _goalService = SavingsGoalService();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  // Hiển thị dialog nhập số tiền góp thêm
  void _showContributeDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.add_circle, color: AppColors.success),
              const SizedBox(width: 12),
              Text('Góp tiền', style: AppTextStyles.h3),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Số tiền (₫)',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (không bắt buộc)',
                  hintText: 'Nguồn tiền...',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = amountController.text.trim();
                if (amountText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập số tiền')),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Số tiền không hợp lệ')),
                  );
                  return;
                }

                try {
                  await _goalService.addContribution(
                    goalId: widget.goal.id,
                    amount: amount,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Góp tiền thành công!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: AppColors.error),
              const SizedBox(width: 12),
              Text('Xóa mục tiêu?', style: AppTextStyles.h3),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa mục tiêu này? Hành động này không thể hoàn tác.',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _goalService.deleteGoal(widget.goal.id);
                  if (mounted) {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close detail screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa mục tiêu')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SavingsGoalModel?>(
      stream: _goalService.getGoals(widget.goal.userId).map((goals) {
        try {
          return goals.firstWhere((g) => g.id == widget.goal.id);
        } catch (e) {
          return null;
        }
      }),
      builder: (context, snapshot) {
        // Lấy dữ liệu và tính toán các chỉ số hiển thị
        final goal = snapshot.data ?? widget.goal;
        final goalColor = Color(int.parse('0x${goal.color}'));
        final progress = goal.getProgressPercentage(); // Phần trăm hoàn thành
        final daysRemaining = goal
            .getDaysRemaining(); // Số ngày còn lại đến hạn
        final status = goal
            .getStatus(); // Trạng thái: completed, behind, on_track...

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [goalColor, goalColor.withOpacity(0.8)],
                ),
              ),
            ),
            title: const Text('Chi Tiết Mục Tiêu'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Chỉnh sửa',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddEditSavingsGoalScreen(goal: goal),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Xóa',
                onPressed: _showDeleteDialog,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 100),

              // Progress Circle
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: (progress / 100).clamp(0.0, 1.0),
                          strokeWidth: 12,
                          backgroundColor: AppColors.surface.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                        ),
                      ),
                      // Progress text
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIconData(goal.iconName),
                            size: 48,
                            color: goalColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${progress.toStringAsFixed(1)}%',
                            style: AppTextStyles.h1.copyWith(
                              color: goalColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Goal name and status
              Center(
                child: Column(
                  children: [
                    Text(
                      goal.name,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(status, daysRemaining),
                  ],
                ),
              ),

              if (goal.description != null && goal.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    goal.description!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Amount cards
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Đã tiết kiệm',
                      currencyFormat.format(goal.currentAmount),
                      Icons.savings,
                      goalColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Mục tiêu',
                      currencyFormat.format(goal.targetAmount),
                      Icons.flag,
                      AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Còn thiếu',
                      currencyFormat.format(goal.getRemainingAmount()),
                      Icons.trending_up,
                      goal.isCompleted()
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Hạn chót',
                      DateFormat('dd/MM/yyyy').format(goal.deadline),
                      Icons.calendar_today,
                      daysRemaining < 7 && !goal.isCompleted()
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Contribute button
              if (!goal.isCompleted())
                GradientButton(
                  onPressed: _showContributeDialog,
                  gradient: LinearGradient(
                    colors: [goalColor, goalColor.withOpacity(0.8)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Góp tiền',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Contributions history
              Text(
                'Lịch sử góp tiền',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _goalService.getContributions(goal.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final contributions = snapshot.data ?? [];

                  if (contributions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có lần góp nào',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contributions.length,
                    itemBuilder: (context, index) {
                      final contribution = contributions[index];
                      final amount = contribution['amount'] as double;
                      final note = contribution['note'] as String?;
                      final createdAt = contribution['createdAt'] as DateTime;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currencyFormat.format(amount),
                                    style: AppTextStyles.h3.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (note != null && note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      note,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(createdAt),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, int daysRemaining) {
    String label;
    Color color;
    IconData icon;

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
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

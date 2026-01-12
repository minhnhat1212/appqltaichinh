import 'package:flutter/material.dart'; // UI Flutter
import '../models/budget_model.dart'; // Model ngân sách
import '../models/transaction_model.dart'; // Model giao dịch
import '../services/budget_service.dart'; // Service CRUD ngân sách (xóa, sửa,...)
import '../services/transaction_service.dart'; // Service stream/list giao dịch
import '../theme.dart'; // Màu sắc + text style chung
import '../utils/budget_utils.dart'; // Hàm tiện ích: format tiền, period, gradient theo cảnh báo
import '../widgets/transaction_card.dart'; // Widget hiển thị 1 giao dịch
import 'add_edit_budget_screen.dart'; // Màn hình sửa/tạo ngân sách

/// Màn hình chi tiết của 1 ngân sách:
/// - Hiển thị tiến độ (đã dùng / tổng)
/// - Hiển thị số còn lại
/// - Danh sách giao dịch liên quan trong khoảng thời gian ngân sách
/// - Cho phép sửa / xóa ngân sách
class BudgetDetailScreen extends StatefulWidget {
  final BudgetModel budget; // ngân sách cần xem chi tiết
  final double spentAmount; // số tiền đã chi (tính trước và truyền vào)

  const BudgetDetailScreen({
    super.key,
    required this.budget,
    required this.spentAmount,
  });

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  /// Service thao tác ngân sách
  final BudgetService _budgetService = BudgetService();

  /// Service lấy danh sách giao dịch (stream)
  final TransactionService _transactionService = TransactionService();

  /// Xóa ngân sách:
  /// 1) showDialog xác nhận
  /// 2) gọi service deleteBudget
  /// 3) thông báo SnackBar + pop màn hình
  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa ngân sách này?'),
        actions: [
          // Hủy => trả về false
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          // Xóa => trả về true
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    // Nếu user xác nhận xóa
    if (confirmed == true) {
      try {
        // Xóa theo budgetId
        await _budgetService.deleteBudget(widget.budget.id);

        if (mounted) {
          // Thông báo thành công
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa ngân sách')),
          );

          // Đóng màn hình chi tiết về màn trước
          Navigator.pop(context);
        }
      } catch (e) {
        // Nếu lỗi => show SnackBar lỗi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Tính % đã dùng dựa trên spentAmount truyền vào
    final percentage = widget.budget.getProgressPercentage(widget.spentAmount);

    /// Số tiền còn lại = budget.amount - spentAmount
    final remaining = widget.budget.getRemainingAmount(widget.spentAmount);

    /// Mức cảnh báo (ví dụ: safe / warning / danger...) tùy theo budget model
    final alertLevel = widget.budget.getAlertLevel(widget.spentAmount);

    /// Chọn gradient theo alertLevel (đẹp + trực quan)
    final gradient = BudgetUtils.getBudgetGradient(alertLevel);

    return Scaffold(
      // Cho body “đè” lên AppBar để header liền mạch
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Tô nền AppBar bằng gradient tương ứng mức cảnh báo
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        title: const Text('Chi Tiết Ngân Sách'),
        actions: [
          // Nút sửa => push sang màn hình AddEditBudgetScreen với budget hiện tại
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddEditBudgetScreen(budget: widget.budget),
                ),
              );
            },
          ),
          // Nút xóa => gọi _deleteBudget
          IconButton(icon: const Icon(Icons.delete), onPressed: _deleteBudget),
        ],
      ),

      body: Column(
        children: [
          // =========================================================
          // HEADER: thông tin ngân sách + progress (gradient)
          // =========================================================
          Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: gradient),
            // top padding 100 để tránh đè AppBar (vì extendBodyBehindAppBar)
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
            child: Column(
              children: [
                // Tên ngân sách
                Text(
                  widget.budget.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Khoảng thời gian ngân sách (format bởi BudgetUtils)
                Text(
                  BudgetUtils.formatBudgetPeriod(widget.budget),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 24),

                // =========================================================
                // VÒNG TRÒN TIẾN ĐỘ (Circular Progress)
                // - Vòng nền (mờ)
                // - Vòng tiến độ (trắng)
                // - Text phần trăm + cảnh báo
                // =========================================================
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle: luôn 100% (value = 1.0) để làm nền
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),

                      // Progress circle: % đã dùng (clamp 0..1 để tránh vượt)
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: (percentage / 100).clamp(0.0, 1.0),
                          strokeWidth: 12,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),

                      // Text ở giữa vòng tròn
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Hiển thị phần trăm với 1 chữ số thập phân
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          // Text cảnh báo theo alert level và % (ví dụ: "An toàn", "Sắp vượt", "Đã vượt"...)
                          Text(
                            BudgetUtils.getBudgetAlertText(
                              alertLevel,
                              percentage,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =========================================================
                // STATS ROW: Tổng số / Đã dùng / Còn lại
                // =========================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Tổng số',
                      BudgetUtils.formatCurrency(widget.budget.amount),
                      Icons.account_balance_wallet,
                    ),
                    _buildStatCard(
                      'Đã dùng',
                      BudgetUtils.formatCurrency(widget.spentAmount),
                      Icons.shopping_cart,
                    ),
                    _buildStatCard(
                      'Còn lại',
                      // Nếu remaining âm => hiển thị dạng "-xxx"
                      remaining >= 0
                          ? BudgetUtils.formatCurrency(remaining)
                          : '-${BudgetUtils.formatCurrency(-remaining)}',
                      Icons.savings,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // =========================================================
          // LIST GIAO DỊCH LIÊN QUAN TỚI NGÂN SÁCH
          // =========================================================
          Expanded(
            child: Container(
              color: AppColors.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Giao dịch liên quan', style: AppTextStyles.h3),
                  ),

                  // Stream giao dịch theo userId
                  Expanded(
                    child: StreamBuilder<List<TransactionModel>>(
                      stream: _transactionService.getTransactions(
                        widget.budget.userId,
                      ),
                      builder: (context, snapshot) {
                        // Đang load stream
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final allTransactions = snapshot.data ?? [];

                        // Lọc các giao dịch thuộc ngân sách:
                        // 1) Chỉ expense (chi tiêu) vì ngân sách thường tính chi
                        // 2) Trong khoảng startDate..endDate
                        // 3) Nếu budget có categoryId => phải đúng categoryId đó
                        final transactions = allTransactions.where((t) {
                          if (t.type != 'expense') return false;

                          if (t.date.isBefore(widget.budget.startDate) ||
                              t.date.isAfter(widget.budget.endDate)) {
                            return false;
                          }

                          if (widget.budget.categoryId != null &&
                              t.categoryId != widget.budget.categoryId) {
                            return false;
                          }

                          return true;
                        }).toList();

                        // Không có giao dịch
                        if (transactions.isEmpty) {
                          return const Center(
                            child: Text('Chưa có giao dịch nào'),
                          );
                        }

                        // Danh sách giao dịch bằng ListView
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return TransactionCard(
                              transaction: transactions[index],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card nhỏ hiển thị 1 chỉ số: icon + label + value
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Trắng trong suốt để nổi trên nền gradient
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

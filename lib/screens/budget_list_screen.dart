import 'package:flutter/material.dart'; // UI Flutter
import '../models/budget_model.dart'; // Model ngân sách
import '../services/budget_service.dart'; // Service lấy budgets + spent amounts
import '../widgets/budget_card.dart'; // Widget hiển thị 1 ngân sách dạng card
import '../theme.dart'; // Theme chung: màu, text style, animation duration,...
import 'add_edit_budget_screen.dart'; // Màn hình tạo/sửa ngân sách
import 'budget_detail_screen.dart'; // Màn hình chi tiết ngân sách
import 'package:firebase_auth/firebase_auth.dart'; // Lấy uid user hiện tại

/// Màn hình danh sách ngân sách:
/// - Tab 1: Đang hoạt động
/// - Tab 2: Đã kết thúc
/// - FAB: tạo ngân sách mới
class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen>
    with SingleTickerProviderStateMixin {
  /// Service thao tác dữ liệu ngân sách (stream budgets, spent amounts)
  final BudgetService _budgetService = BudgetService();

  /// TabController quản lý TabBar + TabBarView
  late TabController _tabController;

  /// uid user hiện tại (giả định user đã đăng nhập)
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();

    /// Có 2 tab => length = 2
    /// vsync: this (SingleTickerProviderStateMixin) giúp animation mượt
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    /// Dispose tabController để tránh leak
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cho body “đè” lên appbar để nền gradient đẹp hơn
      extendBodyBehindAppBar: true,

      // =========================
      // APP BAR + TAB BAR
      // =========================
      appBar: AppBar(
        // Nền AppBar là gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: const Text('Ngân Sách'),

        // TabBar nằm dưới AppBar
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white, // màu gạch chân tab được chọn
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Đang hoạt động'),
            Tab(text: 'Đã kết thúc'),
          ],
        ),
      ),

      // =========================
      // TAB VIEW: mỗi tab là 1 list riêng
      // =========================
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: chỉ ngân sách còn active
          _buildBudgetList(activeOnly: true),

          // Tab 2: chỉ ngân sách đã kết thúc
          _buildBudgetList(activeOnly: false),
        ],
      ),

      // =========================
      // FAB: tạo ngân sách mới
      // =========================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Mở màn hình tạo ngân sách
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditBudgetScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo ngân sách'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// Build danh sách ngân sách theo trạng thái:
  /// - activeOnly = true  => chỉ ngân sách đang hoạt động
  /// - activeOnly = false => chỉ ngân sách đã kết thúc
  Widget _buildBudgetList({required bool activeOnly}) {
    return StreamBuilder<List<BudgetModel>>(
      // Stream lấy toàn bộ budgets của user
      stream: _budgetService.getBudgets(userId),
      builder: (context, budgetSnapshot) {
        // Đang chờ dữ liệu => shimmer loading
        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        // Có lỗi => màn hình lỗi
        if (budgetSnapshot.hasError) {
          return _buildError(budgetSnapshot.error.toString());
        }

        // Nếu không có data => list rỗng
        final allBudgets = budgetSnapshot.data ?? [];

        // Lọc theo active status
        // budget.isActive() thường dựa trên thời gian hiện tại so với start/end
        final budgets = allBudgets.where((budget) {
          final isActive = budget.isActive();
          return activeOnly ? isActive : !isActive;
        }).toList();

        // Không có ngân sách phù hợp => empty state
        if (budgets.isEmpty) {
          return _buildEmptyState(activeOnly);
        }

        // =========================================================
        // ✅ TỐI ƯU:
        // Lấy spentAmount cho N budgets bằng 1 stream Map<budgetId, spent>
        // Thay vì tính lại trong từng item (tránh O(n²))
        // =========================================================
        return StreamBuilder<Map<String, double>>(
          stream: _budgetService.getBudgetSpentAmounts(userId, budgets),
          builder: (context, spentSnapshot) {
            // Trong lúc spent đang tính, vẫn show list với spent default = 0
            final spentAmounts = spentSnapshot.data ?? {};

            return RefreshIndicator(
              // RefreshIndicator ở đây chỉ tạo UX kéo để refresh
              // thực tế stream đã tự cập nhật, nên bạn delay nhẹ là đủ
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                // top padding để list không bị dính sát AppBar
                padding: const EdgeInsets.only(top: 16, bottom: 100),
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];

                  // ✅ Lookup O(1): lấy spent theo budget.id từ map
                  final spentAmount = spentAmounts[budget.id] ?? 0;

                  // Animation nhẹ (hiện tại opacity luôn 1.0)
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: AppTheme.animationDuration,
                    child: BudgetCard(
                      budget: budget,
                      spentAmount: spentAmount,
                      onTap: () {
                        // Mở màn hình chi tiết và truyền budget + spentAmount
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BudgetDetailScreen(
                              budget: budget,
                              spentAmount: spentAmount,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// UI khi không có ngân sách (tùy tab)
  Widget _buildEmptyState(bool activeOnly) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            activeOnly ? Icons.account_balance_wallet : Icons.history,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            activeOnly
                ? 'Chưa có ngân sách nào'
                : 'Chưa có ngân sách đã kết thúc',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            activeOnly
                ? 'Tạo ngân sách để quản lý chi tiêu của bạn'
                : 'Ngân sách đã kết thúc sẽ hiển thị ở đây',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Shimmer loading giả (các khối xám)
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  /// UI lỗi
  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: AppTextStyles.h3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

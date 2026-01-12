import 'package:flutter/material.dart';
import '../models/savings_goal_model.dart';
import '../services/savings_goal_service.dart';
import '../widgets/savings_goal_card.dart';
import '../theme.dart';
import 'add_edit_savings_goal_screen.dart';
import 'savings_goal_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Màn hình danh sách mục tiêu tiết kiệm
/// Hiển thị tab "Đang hoạt động" và "Đã hoàn thành" với khả năng thêm mới
class SavingsGoalListScreen extends StatefulWidget {
  const SavingsGoalListScreen({super.key});

  @override
  State<SavingsGoalListScreen> createState() => _SavingsGoalListScreenState();
}

class _SavingsGoalListScreenState extends State<SavingsGoalListScreen>
    with SingleTickerProviderStateMixin {
  final SavingsGoalService _goalService = SavingsGoalService();
  late TabController _tabController;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: const Text('Mục Tiêu Tiết Kiệm'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Đang thực hiện'),
            Tab(text: 'Đã hoàn thành'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Danh sách mục tiêu đang thực hiện (chưa hoàn thành)
          _buildGoalList(activeOnly: true),

          // Tab 2: Danh sách mục tiêu đã hoàn thành (đạt 100%)
          _buildGoalList(activeOnly: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditSavingsGoalScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo mục tiêu'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // Build danh sách mục tiêu dựa trên trạng thái (active/completed)
  Widget _buildGoalList({required bool activeOnly}) {
    return StreamBuilder<List<SavingsGoalModel>>(
      // Stream lấy danh sách mục tiêu từ Firestore theo userId và trạng thái
      stream: activeOnly
          ? _goalService.getActiveGoals(userId)
          : _goalService.getCompletedGoals(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        final goals = snapshot.data ?? [];

        if (goals.isEmpty) {
          return _buildEmptyState(activeOnly);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh is handled automatically by streams
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];

              return AnimatedOpacity(
                opacity: 1.0,
                duration: AppTheme.animationDuration,
                child: SavingsGoalCard(
                  goal: goal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SavingsGoalDetailScreen(goal: goal),
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
  }

  Widget _buildEmptyState(bool activeOnly) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              activeOnly ? Icons.savings : Icons.emoji_events,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              activeOnly
                  ? 'Chưa có mục tiêu nào'
                  : 'Chưa hoàn thành mục tiêu nào',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              activeOnly
                  ? 'Tạo mục tiêu tiết kiệm để bắt đầu\nlên kế hoạch tài chính của bạn'
                  : 'Mục tiêu đã hoàn thành sẽ hiển thị ở đây',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.shimmerBase,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
      ),
    );
  }
}

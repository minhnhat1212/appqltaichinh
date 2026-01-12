import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/balance_summary_card.dart';
import 'profile_screen.dart';
import 'transaction_list_screen.dart';
import 'wallet_list_screen.dart';
import 'budget_list_screen.dart';
import 'savings_goal_list_screen.dart';
import 'statistics_screen.dart';
import 'category_list_screen.dart';

/// Màn hình chính của ứng dụng
/// Hiển thị tổng số dư, danh sách giao dịch gần đây và các nút điều hướng
class HomeScreen extends StatelessWidget {
  final String uid;

  const HomeScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar:
          true, // Cho phép body tràn lên dưới AppBar (để thấy gradient)
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: const Text('Quản Lý Tài Chính'),
        // Các nút điều hướng nhanh trên AppBar
        actions: [
          // Nút Danh mục
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Danh mục',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoryListScreen()),
              );
            },
          ),
          // Nút Ví
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Ví của tôi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WalletListScreen()),
              );
            },
          ),
          // Nút Mục tiêu tiết kiệm
          IconButton(
            icon: const Icon(Icons.savings),
            tooltip: 'Mục tiêu tiết kiệm',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SavingsGoalListScreen(),
                ),
              );
            },
          ),
          // Nút Thống kê
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Thống kê',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
          ),
          // Nút Ngân sách
          IconButton(
            icon: const Icon(Icons.account_balance),
            tooltip: 'Ngân sách',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BudgetListScreen()),
              );
            },
          ),
          // Nút Hồ sơ cá nhân
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Hồ sơ',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Widget hiển thị tổng số dư (Card trên cùng)
          SafeArea(bottom: false, child: BalanceSummaryCard(userId: uid)),

          // Danh sách giao dịch gần đây (chiếm phần còn lại màn hình)
          Expanded(child: TransactionListScreen(userId: uid)),
        ],
      ),
    );
  }
}

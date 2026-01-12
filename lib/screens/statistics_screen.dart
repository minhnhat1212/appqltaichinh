import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/filter_options.dart';
import '../services/statistics_service.dart';
import '../services/query_combiner_service.dart';
import '../widgets/period_summary_card.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/income_expense_chart.dart';
import '../widgets/top_categories_widget.dart';
import '../widgets/statistics_filter_widget.dart';

/// Màn hình thống kê tài chính
/// Hiển thị biểu đồ, tổng kết theo khoảng thời gian, top danh mục và các bộ lọc
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();

  // Dùng QueryCombinerService để gom nhiều luồng dữ liệu (Transaction, Category, Wallet)
  // giúp tối ưu performance thay vì lồng nhiều StreamBuilder
  final QueryCombinerService _queryCombiner = QueryCombinerService();

  String _selectedPeriod = 'month'; // Kỳ hạn thống kê mặc định (theo tháng)
  FilterOptions _filters = FilterOptions(); // Các bộ lọc đang áp dụng

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, user.uid),
              Expanded(
                // ✅ OPTIMIZED: Sử dụng 1 StreamBuilder duy nhất lấy tất cả dữ liệu cần thiết
                child: StreamBuilder(
                  stream: _queryCombiner.getStatisticsData(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Có lỗi xảy ra: ${snapshot.error}'),
                      );
                    }

                    final data = snapshot.data;
                    if (data == null || data.isEmpty) {
                      return const Center(child: Text('Chưa có dữ liệu'));
                    }

                    // 1. Áp dụng bộ lọc (ví, danh mục, tag...)
                    final filteredTransactions = _statisticsService
                        .applyFilters(data.transactions, _filters);

                    // 2. Tính toán tổng quan kỳ (Thu, Chi, Số dư đầu/cuối kì)
                    final summary = _statisticsService.getPeriodSummary(
                      filteredTransactions,
                      _selectedPeriod,
                      DateTime.now(),
                    );

                    // 3. Tính toán chi tiêu theo danh mục (cho biểu đồ tròn)
                    final categorySpending = _statisticsService
                        .getCategorySpending(
                          filteredTransactions,
                          data.categories,
                          type: 'expense',
                        );

                    // 4. Lấy top các danh mục chi tiêu nhiều nhất
                    final topCategories = _statisticsService.getTopCategories(
                      filteredTransactions,
                      data.categories,
                      limit: 5,
                      type: 'expense',
                    );

                    // 5. Chuẩn bị dữ liệu cho biểu đồ đường (Thu nhập vs Chi tiêu theo thời gian)
                    DateTime seriesStart;
                    DateTime seriesEnd = DateTime.now();
                    String groupBy;

                    switch (_selectedPeriod) {
                      case 'week':
                        seriesStart = DateTime.now().subtract(
                          const Duration(days: 7),
                        );
                        groupBy = 'day';
                        break;
                      case 'month':
                        seriesStart = DateTime.now().subtract(
                          const Duration(days: 30),
                        );
                        groupBy = 'day';
                        break;
                      case 'year':
                        seriesStart = DateTime.now().subtract(
                          const Duration(days: 365),
                        );
                        groupBy = 'month';
                        break;
                      default:
                        seriesStart = DateTime.now().subtract(
                          const Duration(days: 7),
                        );
                        groupBy = 'day';
                    }

                    final timeSeriesData = _statisticsService.getTimeSeriesData(
                      filteredTransactions,
                      seriesStart,
                      seriesEnd,
                      groupBy,
                    );

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Period Summary Card
                          PeriodSummaryCard(
                            summary: summary,
                            selectedPeriod: _selectedPeriod,
                            onPeriodChanged: (period) {
                              setState(() {
                                _selectedPeriod = period;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Category Pie Chart
                          CategoryPieChart(categoryData: categorySpending),

                          const SizedBox(height: 16),

                          // Income vs Expense Chart
                          IncomeExpenseChart(timeSeriesData: timeSeriesData),

                          const SizedBox(height: 16),

                          // Top Categories
                          TopCategoriesWidget(topCategories: topCategories),

                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String userId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Thống kê & Báo cáo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Filter button - also using combined stream
          StreamBuilder(
            stream: _queryCombiner.getStatisticsData(userId),
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return const SizedBox.shrink();
              }

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: StatisticsFilterWidget(
                            currentFilters: _filters,
                            categories: data.categories,
                            wallets: data.wallets,
                            availableTags: data.allTags.toList(),
                            onApplyFilters: (filters) {
                              setState(() {
                                _filters = filters;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  if (_filters.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
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

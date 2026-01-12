import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/filter_options.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';
import '../services/statistics_service.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../widgets/period_summary_card.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/income_expense_chart.dart';
import '../widgets/top_categories_widget.dart';
import '../widgets/statistics_filter_widget.dart';
import '../theme.dart';

/// Màn hình thống kê tài chính
/// Hiển thị biểu đồ, tổng kết theo khoảng thời gian, top danh mục
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();

  String _selectedPeriod = 'month'; // Kỳ hạn thống kê mặc định (theo tháng)
  late DateTime _startDate;
  late DateTime _endDate;
  FilterOptions _filters = FilterOptions();

  @override
  void initState() {
    super.initState();
    _updateDateRange(_selectedPeriod);
  }

  // Cập nhật khoảng thời gian start/end dựa trên period được chọn
  void _updateDateRange(String period) {
    DateTime now = DateTime.now();
    switch (period) {
      case 'day':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate.add(const Duration(days: 1));
        break;
      case 'week':
        int weekday = now.weekday;
        _startDate = DateTime(now.year, now.month, now.day - (weekday - 1));
        _endDate = _startDate.add(const Duration(days: 7));
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 1);
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year + 1, 1, 1);
        break;
      default:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 1);
    }
  }

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
                // Kết hợp stream categories và transactions
                // Categories chỉ load 1 lần, Transactions load lại khi đổi period
                child: StreamBuilder<List<CategoryModel>>(
                  stream: _transactionService.getCategories(),
                  builder: (context, categorySnapshot) {
                    final categories = categorySnapshot.data ?? [];

                    return StreamBuilder<List<TransactionModel>>(
                      // Chỉ lấy transactions trong khoảng thời gian đã chọn
                      stream: _transactionService.getTransactionsForPeriod(
                        user.uid,
                        _startDate,
                        _endDate,
                      ),
                      builder: (context, transactionSnapshot) {
                        // Hiển thị loading skeleton khi đang tải dữ liệu
                        if (transactionSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildShimmerLoading();
                        }

                        if (transactionSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'Có lỗi xảy ra: ${transactionSnapshot.error}',
                            ),
                          );
                        }

                        final transactions = transactionSnapshot.data ?? [];

                        // Áp dụng bộ lọc local (ví, tag, category...)
                        final filteredTransactions = _statisticsService
                            .applyFilters(transactions, _filters);

                        if (filteredTransactions.isEmpty) {
                          return _buildEmptyState();
                        }

                        return _buildStatisticsContent(
                          filteredTransactions,
                          categories,
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
    );
  }

  Widget _buildStatisticsContent(
    List<TransactionModel> transactions,
    List<CategoryModel> categories,
  ) {
    // 2. Tính toán tổng quan kỳ
    final summary = _statisticsService.getPeriodSummary(
      transactions,
      _selectedPeriod,
      DateTime.now(), // Reference date (để tính today/this week...)
    );

    // 3. Tính toán chi tiêu (cho Pie Chart)
    final categorySpending = _statisticsService.getCategorySpending(
      transactions,
      categories,
      type: 'expense',
    );

    // 4. Time Series Data (cho Line Chart)
    String groupBy = 'day';
    if (_selectedPeriod == 'month')
      groupBy = 'day';
    else if (_selectedPeriod == 'year')
      groupBy = 'month';

    final timeSeriesData = _statisticsService.getTimeSeriesData(
      transactions,
      _startDate,
      _endDate,
      groupBy,
    );

    // 5. Top Categories
    final topCategories = _statisticsService.getTopCategories(
      transactions,
      categories,
      limit: 5,
      type: 'expense',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          // Widget chọn kỳ và hiển thị tổng quan
          PeriodSummaryCard(
            summary: summary,
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (period) {
              setState(() {
                _selectedPeriod = period;
                _updateDateRange(period);
              });
            },
          ),
          const SizedBox(height: 16),
          CategoryPieChart(categoryData: categorySpending),
          const SizedBox(height: 16),
          IncomeExpenseChart(timeSeriesData: timeSeriesData),
          const SizedBox(height: 16),
          TopCategoriesWidget(topCategories: topCategories),
        ],
      ),
    );
  }

  // Loading Skeleton effect
  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Widget PeriodSummaryCard vẫn hiển thị để user có thể đổi kỳ khác
          PeriodSummaryCard(
            summary: _statisticsService.getPeriodSummary(
              [],
              _selectedPeriod,
              DateTime.now(),
            ),
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (period) {
              setState(() {
                _selectedPeriod = period;
                _updateDateRange(period);
              });
            },
          ),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 80, color: AppColors.textHint),
                SizedBox(height: 16),
                Text(
                  'Chưa có dữ liệu cho kỳ này',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
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
          // Filter Button - cần lấy Wallets và Categories để passing vào FilterWidget
          StreamBuilder<List<WalletModel>>(
            stream: _walletService.getWallets(userId),
            builder: (context, walletSnapshot) {
              return StreamBuilder<List<CategoryModel>>(
                stream: _transactionService.getCategories(),
                builder: (context, categorySnapshot) {
                  // Nút filter
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (!walletSnapshot.hasData ||
                              !categorySnapshot.hasData)
                            return;

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: StatisticsFilterWidget(
                                currentFilters: _filters,
                                categories: categorySnapshot.data!,
                                wallets: walletSnapshot.data!,
                                availableTags: const [], // Tạm thời để trống
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
              );
            },
          ),
        ],
      ),
    );
  }
}

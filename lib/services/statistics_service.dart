import 'package:flutter/material.dart'; // Import Material để sử dụng Color
import '../models/transaction_model.dart'; // Import TransactionModel
import '../models/category_model.dart'; // Import CategoryModel
import '../models/statistics_data.dart'; // Import các models thống kê
import '../models/filter_options.dart'; // Import FilterOptions

/// Service xử lý thống kê và phân tích dữ liệu giao dịch
/// Tính toán summary, category spending, time series, top categories
class StatisticsService {
  /// Lấy tổng kết theo khoảng thời gian (day/week/month/year)
  /// Return: PeriodSummary chứa income, expense, net cho period
  PeriodSummary getPeriodSummary(
    List<TransactionModel> transactions,
    String period,
    DateTime referenceDate,
  ) {
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'day': // Ngày cụ thể
        startDate = DateTime(
          referenceDate.year,
          referenceDate.month,
          referenceDate.day,
        );
        endDate = startDate.add(const Duration(days: 1));
        break;
      case 'week': // Tuần (bắt đầu từ thứ 2)
        final weekday = referenceDate.weekday;
        startDate = DateTime(
          referenceDate.year,
          referenceDate.month,
          referenceDate.day - (weekday - 1),
        );
        endDate = startDate.add(const Duration(days: 7));
        break;
      case 'month': // Tháng
        startDate = DateTime(referenceDate.year, referenceDate.month, 1);
        endDate = DateTime(referenceDate.year, referenceDate.month + 1, 1);
        break;
      case 'year': // Năm
        startDate = DateTime(referenceDate.year, 1, 1);
        endDate = DateTime(referenceDate.year + 1, 1, 1);
        break;
      default:
        startDate = DateTime.now();
        endDate = DateTime.now();
    }

    // Lọc transactions trong khoảng thời gian
    final periodTransactions = transactions.where((t) {
      return t.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(endDate);
    }).toList();

    double income = 0;
    double expense = 0;

    for (var transaction in periodTransactions) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
    }

    return PeriodSummary(
      income: income,
      expense: expense,
      net: income - expense, // Lợi nhuận ròng
      period: period,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Lấy chi tiêu theo danh mục với phần trăm
  /// Return: List CategorySpending đã sắp xếp theo amount giảm dần
  List<CategorySpending> getCategorySpending(
    List<TransactionModel> transactions,
    List<CategoryModel> categories, {
    String? type, // 'income' hoặc 'expense' hoặc null (cả hai)
  }) {
    // Lọc theo type nếu có
    final filteredTransactions = type != null
        ? transactions.where((t) => t.type == type).toList()
        : transactions;

    // Nhóm theo category
    Map<String, double> categoryTotals = {};
    Map<String, int> categoryCount = {};

    for (var transaction in filteredTransactions) {
      categoryTotals[transaction.categoryId] =
          (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount;
      categoryCount[transaction.categoryId] =
          (categoryCount[transaction.categoryId] ?? 0) + 1;
    }

    // Tính tổng để tính phần trăm
    double total = categoryTotals.values.fold(0, (sum, amount) => sum + amount);

    // Tạo danh sách CategorySpending
    List<CategorySpending> result = [];
    final colors = _generateColors(
      categoryTotals.length,
    ); // Tạo màu cho từng category
    int colorIndex = 0;

    categoryTotals.forEach((categoryId, amount) {
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => CategoryModel(
          id: categoryId,
          name: 'Khác',
          icon: 'help_outline',
          type: 'expense',
        ),
      );

      result.add(
        CategorySpending(
          categoryId: categoryId,
          categoryName: category.name,
          categoryIcon: category.icon,
          amount: amount,
          percentage: total > 0 ? (amount / total) * 100 : 0, // Tính phần trăm
          color: colors[colorIndex % colors.length],
          transactionCount: categoryCount[categoryId] ?? 0,
        ),
      );

      colorIndex++;
    });

    result.sort(
      (a, b) => b.amount.compareTo(a.amount),
    ); // Sắp xếp theo amount giảm dần

    return result;
  }

  /// Lấy dữ liệu time series cho biểu đồ
  /// Return: List TimeSeriesData cho từng period (day/week/month)
  List<TimeSeriesData> getTimeSeriesData(
    List<TransactionModel> transactions,
    DateTime startDate,
    DateTime endDate,
    String groupBy, // 'day', 'week', 'month'
  ) {
    List<TimeSeriesData> result = [];
    DateTime current = startDate;

    while (current.isBefore(endDate)) {
      DateTime periodStart = current;
      DateTime periodEnd;

      switch (groupBy) {
        case 'day':
          periodEnd = current.add(const Duration(days: 1));
          break;
        case 'week':
          periodEnd = current.add(const Duration(days: 7));
          break;
        case 'month':
          periodEnd = DateTime(current.year, current.month + 1, 1);
          break;
        default:
          periodEnd = current.add(const Duration(days: 1));
      }

      // Lọc transactions cho period này
      final periodTransactions = transactions.where((t) {
        return t.date.isAfter(
              periodStart.subtract(const Duration(seconds: 1)),
            ) &&
            t.date.isBefore(periodEnd);
      }).toList();

      double income = 0;
      double expense = 0;

      for (var transaction in periodTransactions) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      result.add(
        TimeSeriesData(date: periodStart, income: income, expense: expense),
      );

      current = periodEnd; // Chuyển sang period tiếp theo
    }

    return result;
  }

  /// Lấy top categories chi tiêu nhiều nhất
  /// Return: List TopCategory đã sắp xếp theo amount
  List<TopCategory> getTopCategories(
    List<TransactionModel> transactions,
    List<CategoryModel> categories, {
    int limit = 5, // Số lượng top categories
    String? type, // 'income' hoặc 'expense'
  }) {
    final categorySpending = getCategorySpending(
      transactions,
      categories,
      type: type,
    );

    List<TopCategory> result = [];
    final total = categorySpending.fold(0.0, (sum, c) => sum + c.amount);

    for (int i = 0; i < categorySpending.length && i < limit; i++) {
      final spending = categorySpending[i];
      result.add(
        TopCategory(
          rank: i + 1, // Thứ hạng (1 = cao nhất)
          categoryId: spending.categoryId,
          categoryName: spending.categoryName,
          categoryIcon: spending.categoryIcon,
          amount: spending.amount,
          percentage: total > 0 ? (spending.amount / total) * 100 : 0,
          transactionCount: spending.transactionCount,
        ),
      );
    }

    return result;
  }

  /// Áp dụng filters lên danh sách transactions
  /// Return: Danh sách transactions đã được lọc
  List<TransactionModel> applyFilters(
    List<TransactionModel> transactions,
    FilterOptions filters,
  ) {
    return filters.applyToTransactions(transactions);
  }

  /// Helper: Tạo màu sắc phân biệt cho categories
  /// Return: List Color cho từng category
  List<Color> _generateColors(int count) {
    final List<Color> baseColors = [
      const Color(0xFFFF6B9D), // Pink
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFFFFA07A), // Light Salmon
      const Color(0xFF98D8C8), // Mint
      const Color(0xFFC7CEEA), // Lavender
      const Color(0xFFFFD93D), // Yellow
      const Color(0xFF6BCF7F), // Green
      const Color(0xFFFF8C42), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF3498DB), // Blue
    ];

    if (count <= baseColors.length) {
      return baseColors.sublist(0, count);
    }

    // Tạo thêm màu nếu cần (sử dụng golden angle để phân bố đều)
    List<Color> colors = List.from(baseColors);
    for (int i = baseColors.length; i < count; i++) {
      final hue = (i * 137.5) % 360; // Golden angle = 137.5 degrees
      colors.add(HSLColor.fromAHSL(1.0, hue, 0.6, 0.6).toColor());
    }

    return colors;
  }
}

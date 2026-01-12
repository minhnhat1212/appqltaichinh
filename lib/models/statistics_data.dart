import 'package:flutter/material.dart'; // Import Flutter Material để sử dụng Color
import 'transaction_model.dart'; // Import TransactionModel
import 'category_model.dart'; // Import CategoryModel
import 'wallet_model.dart'; // Import WalletModel

/// Model đại diện cho tổng kết theo khoảng thời gian (ngày/tuần/tháng/năm)
class PeriodSummary {
  final double income; // Tổng thu nhập trong khoảng thời gian
  final double expense; // Tổng chi tiêu trong khoảng thời gian
  final double net; // Lợi nhuận ròng (thu nhập - chi tiêu)
  final String period; // Loại khoảng thời gian: 'day', 'week', 'month', 'year'
  final DateTime startDate; // Ngày bắt đầu của khoảng thời gian
  final DateTime endDate; // Ngày kết thúc của khoảng thời gian

  PeriodSummary({
    required this.income,
    required this.expense,
    required this.net,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  double get total =>
      income + expense; // Tổng giá trị tuyệt đối (thu nhập + chi tiêu)
}

/// Model đại diện cho chi tiêu theo danh mục
class CategorySpending {
  final String categoryId; // ID của danh mục
  final String categoryName; // Tên hiển thị của danh mục
  final String categoryIcon; // Icon của danh mục
  final double amount; // Tổng số tiền chi tiêu cho danh mục này
  final double percentage; // Phần trăm chi tiêu so với tổng chi tiêu (0-100)
  final Color color; // Màu sắc hiển thị cho danh mục trong biểu đồ
  final int transactionCount; // Số lượng giao dịch thuộc danh mục này

  CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.transactionCount,
  });
}

/// Model đại diện cho dữ liệu chuỗi thời gian (Time Series)
/// Sử dụng để vẽ biểu đồ đường hoặc cột theo thời gian
class TimeSeriesData {
  final DateTime date; // Ngày/thời điểm của điểm dữ liệu
  final double income; // Tổng thu nhập tại thời điểm này
  final double expense; // Tổng chi tiêu tại thời điểm này

  TimeSeriesData({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get net => income - expense; // Lợi nhuận ròng (thu nhập - chi tiêu)
}

/// Model đại diện cho danh mục chi tiêu hàng đầu
/// Sử dụng để hiển thị bảng xếp hạng các danh mục chi tiêu nhiều nhất
class TopCategory {
  final int rank; // Thứ hạng của danh mục (1 = cao nhất)
  final String categoryId; // ID của danh mục
  final String categoryName; // Tên hiển thị của danh mục
  final String categoryIcon; // Icon của danh mục
  final double amount; // Tổng số tiền chi tiêu cho danh mục này
  final double percentage; // Phần trăm chi tiêu so với tổng chi tiêu (0-100)
  final int transactionCount; // Số lượng giao dịch thuộc danh mục này

  TopCategory({
    required this.rank,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });
}

/// Model kết hợp tất cả dữ liệu cần thiết cho màn hình thống kê
/// Giúp loại bỏ việc sử dụng nhiều StreamBuilder lồng nhau
class CombinedStatisticsData {
  final List<TransactionModel> transactions; // Danh sách tất cả giao dịch
  final List<CategoryModel> categories; // Danh sách tất cả danh mục
  final List<WalletModel> wallets; // Danh sách tất cả ví
  final Set<String> allTags; // Tập hợp tất cả các tag từ các giao dịch

  CombinedStatisticsData({
    required this.transactions,
    required this.categories,
    required this.wallets,
  }) : allTags = _extractTags(
         transactions,
       ); // Tự động trích xuất tags từ giao dịch

  /// Trích xuất tất cả tag từ danh sách giao dịch
  static Set<String> _extractTags(List<TransactionModel> transactions) {
    final tags = <String>{}; // Tạo Set rỗng để lưu tag
    for (var transaction in transactions) {
      tags.addAll(
        transaction.tags,
      ); // Thêm tất cả tag của giao dịch vào Set (tự động loại bỏ trùng lặp)
    }
    return tags; // Trả về Set chứa tất cả tag duy nhất
  }

  /// Tạo instance rỗng cho trạng thái khởi tạo
  static CombinedStatisticsData empty() {
    return CombinedStatisticsData(
      transactions: [], // Danh sách giao dịch rỗng
      categories: [], // Danh sách danh mục rỗng
      wallets: [], // Danh sách ví rỗng
    );
  }

  /// Kiểm tra xem dữ liệu có rỗng không
  bool get isEmpty =>
      transactions.isEmpty && categories.isEmpty && wallets.isEmpty;

  /// Tạo bản sao CombinedStatisticsData với một số trường được cập nhật
  CombinedStatisticsData copyWith({
    List<TransactionModel>? transactions,
    List<CategoryModel>? categories,
    List<WalletModel>? wallets,
  }) {
    return CombinedStatisticsData(
      transactions:
          transactions ?? this.transactions, // Dùng giá trị mới hoặc giữ nguyên
      categories: categories ?? this.categories,
      wallets: wallets ?? this.wallets,
    );
  }
}

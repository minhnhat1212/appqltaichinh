import 'package:flutter/material.dart'; // Import Flutter Material để sử dụng Color, Icons
import 'package:intl/intl.dart'; // Import intl để format ngày tháng và tiền tệ
import '../models/budget_model.dart'; // Import BudgetModel

/// Class tiện ích chứa các hàm hỗ trợ cho Budget
class BudgetUtils {
  /// Lấy màu sắc dựa trên phần trăm ngân sách
  /// Return: Màu đỏ (>=100%), cam (>=90%), vàng (>=80%), xanh (<80%)
  static Color getBudgetColor(double percentage) {
    if (percentage >= 100) {
      return const Color(0xFFE53935); // Đỏ - vượt ngân sách
    } else if (percentage >= 90) {
      return const Color(0xFFFF6F00); // Cam - nguy hiểm
    } else if (percentage >= 80) {
      return const Color(0xFFFDD835); // Vàng - cảnh báo
    } else {
      return const Color(0xFF43A047); // Xanh - an toàn
    }
  }

  /// Lấy gradient dựa trên mức độ cảnh báo
  /// Return: LinearGradient tương ứng với alertLevel
  static LinearGradient getBudgetGradient(String alertLevel) {
    switch (alertLevel) {
      case 'exceeded': // Vượt ngân sách
        return const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFC62828)], // Gradient đỏ
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'danger': // Nguy hiểm
        return const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFE65100)], // Gradient cam
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'warning': // Cảnh báo
        return const LinearGradient(
          colors: [Color(0xFFFDD835), Color(0xFFF9A825)], // Gradient vàng
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default: // 'safe' - An toàn
        return const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF2E7D32)], // Gradient xanh
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// Lấy icon tương ứng với mức độ cảnh báo
  /// Return: IconData phù hợp với alertLevel
  static IconData getBudgetAlertIcon(String alertLevel) {
    switch (alertLevel) {
      case 'exceeded':
        return Icons.error; // Icon lỗi
      case 'danger':
        return Icons.warning; // Icon cảnh báo
      case 'warning':
        return Icons.info; // Icon thông tin
      default:
        return Icons.check_circle; // Icon hoàn thành
    }
  }

  /// Lấy text cảnh báo dựa trên mức độ và phần trăm
  /// Return: String mô tả trạng thái ngân sách
  static String getBudgetAlertText(String alertLevel, double percentage) {
    switch (alertLevel) {
      case 'exceeded':
        return 'Vượt ngân sách ${percentage.toStringAsFixed(0)}%';
      case 'danger':
        return 'Sắp vượt ngân sách (${percentage.toStringAsFixed(0)}%)';
      case 'warning':
        return 'Cảnh báo (${percentage.toStringAsFixed(0)}%)';
      default:
        return 'Đang an toàn (${percentage.toStringAsFixed(0)}%)';
    }
  }

  /// Format chu kỳ ngân sách thành text hiển thị
  /// Return: String mô tả khoảng thời gian (VD: "Tháng 01/2026", "Tuần 01/01/2026 - 07/01/2026")
  static String formatBudgetPeriod(BudgetModel budget) {
    final dateFormat = DateFormat('dd/MM/yyyy'); // Format ngày tháng

    switch (budget.period) {
      case 'monthly': // Ngân sách theo tháng
        final monthFormat = DateFormat('MM/yyyy');
        return 'Tháng ${monthFormat.format(budget.startDate)}';
      case 'weekly': // Ngân sách theo tuần
        return 'Tuần ${dateFormat.format(budget.startDate)} - ${dateFormat.format(budget.endDate)}';
      default: // Ngân sách tùy chỉnh
        return '${dateFormat.format(budget.startDate)} - ${dateFormat.format(budget.endDate)}';
    }
  }

  /// Kiểm tra xem một ngày có nằm trong chu kỳ ngân sách không
  /// Return: true nếu date nằm trong khoảng [startDate, endDate]
  static bool isDateInBudgetPeriod(DateTime date, BudgetModel budget) {
    return date.isAfter(budget.startDate) &&
        date.isBefore(
          budget.endDate.add(const Duration(days: 1)),
        ); // Cộng 1 ngày để bao gồm cả endDate
  }

  /// Format số tiền theo định dạng tiền Việt Nam
  /// Return: String dạng "1.000.000₫"
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN', // Locale Việt Nam
      symbol: '₫', // Ký hiệu đồng Việt Nam
      decimalDigits: 0, // Không hiển thị số thập phân
    );
    return formatter.format(amount);
  }

  /// Lấy tên hiển thị của chu kỳ ngân sách
  /// Return: String tên chu kỳ bằng tiếng Việt
  static String getPeriodName(String period) {
    switch (period) {
      case 'monthly':
        return 'Theo tháng';
      case 'weekly':
        return 'Theo tuần';
      default:
        return 'Tùy chỉnh';
    }
  }

  /// Tính số ngày còn lại trong chu kỳ ngân sách
  /// Return: Số ngày còn lại (0 nếu đã hết hạn)
  static int getDaysRemaining(BudgetModel budget) {
    final now = DateTime.now(); // Lấy thời gian hiện tại
    if (now.isAfter(budget.endDate)) return 0; // Đã hết hạn
    return budget.endDate.difference(now).inDays; // Tính số ngày còn lại
  }
}

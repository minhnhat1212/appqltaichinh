import '../models/transaction_model.dart';
// Import TransactionModel để sử dụng khi lọc danh sách giao dịch

/// Model chứa các tùy chọn lọc cho thống kê và danh sách giao dịch
/// Cho phép lọc theo ngày, danh mục, ví, tag và loại giao dịch
class FilterOptions {
  // Khai báo class FilterOptions

  final DateTime? startDate;
  // Ngày bắt đầu lọc (null = không lọc theo ngày bắt đầu)

  final DateTime? endDate;
  // Ngày kết thúc lọc (null = không lọc theo ngày kết thúc)

  final List<String> categoryIds;
  // Danh sách ID danh mục cần lọc (rỗng = không lọc theo danh mục)

  final List<String> walletIds;
  // Danh sách ID ví cần lọc (rỗng = không lọc theo ví)

  final List<String> tags;
  // Danh sách tag cần lọc (rỗng = không lọc theo tag)

  final String? transactionType;
  // Loại giao dịch: 'income', 'expense' hoặc null (lọc cả hai)

  FilterOptions({
    // Constructor
    this.startDate, // Gán startDate (tùy chọn)
    this.endDate, // Gán endDate (tùy chọn)
    this.categoryIds = const [], // Mặc định là danh sách rỗng
    this.walletIds = const [], // Mặc định là danh sách rỗng
    this.tags = const [], // Mặc định là danh sách rỗng
    this.transactionType, // Gán loại giao dịch (tùy chọn)
  });

  bool get hasActiveFilters {
    // Getter kiểm tra có bộ lọc nào đang dùng không
    return startDate != null || // Có lọc theo ngày bắt đầu
        endDate != null || // Có lọc theo ngày kết thúc
        categoryIds.isNotEmpty || // Có lọc theo danh mục
        walletIds.isNotEmpty || // Có lọc theo ví
        tags.isNotEmpty || // Có lọc theo tag
        transactionType != null; // Có lọc theo loại giao dịch
  }

  List<TransactionModel> applyToTransactions(
    List<TransactionModel> transactions,
  ) {
    // Áp dụng bộ lọc lên danh sách giao dịch

    return transactions.where((transaction) {
      // Lọc từng giao dịch một

      if (startDate != null && transaction.date.isBefore(startDate!)) {
        return false; // Loại giao dịch trước ngày bắt đầu
      }

      if (endDate != null &&
          transaction.date.isAfter(endDate!.add(const Duration(days: 1)))) {
        return false;
        // Loại giao dịch sau ngày kết thúc
        // Cộng thêm 1 ngày để bao gồm cả endDate
      }

      if (categoryIds.isNotEmpty &&
          !categoryIds.contains(transaction.categoryId)) {
        return false;
        // Loại giao dịch không thuộc danh mục được chọn
      }

      if (walletIds.isNotEmpty && !walletIds.contains(transaction.walletId)) {
        return false;
        // Loại giao dịch không thuộc ví được chọn
      }

      if (tags.isNotEmpty) {
        // Nếu có lọc theo tag
        bool hasMatchingTag = false; // Đánh dấu có tag khớp không

        for (var tag in tags) {
          // Duyệt từng tag cần lọc
          if (transaction.tags.contains(tag)) {
            hasMatchingTag = true; // Tìm thấy tag khớp
            break; // Thoát vòng lặp sớm
          }
        }

        if (!hasMatchingTag) {
          return false;
          // Loại giao dịch nếu không có tag nào khớp
        }
      }

      if (transactionType != null && transaction.type != transactionType) {
        return false;
        // Loại giao dịch không đúng loại (income / expense)
      }

      return true;
      // Giao dịch thỏa mãn tất cả điều kiện lọc
    }).toList();
    // Chuyển Iterable thành List<TransactionModel>
  }

  FilterOptions copyWith({
    // Tạo bản sao FilterOptions
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    List<String>? walletIds,
    List<String>? tags,
    String? transactionType,
    bool clearStartDate = false,
    // true = xóa startDate
    bool clearEndDate = false,
    // true = xóa endDate
    bool clearTransactionType = false,
    // true = xóa transactionType
  }) {
    return FilterOptions(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),

      // Nếu clearStartDate = true thì set null
      // Nếu không thì dùng giá trị mới hoặc giữ giá trị cũ
      endDate: clearEndDate ? null : (endDate ?? this.endDate),

      // Logic tương tự cho endDate
      categoryIds: categoryIds ?? this.categoryIds,

      // Dùng danh sách mới hoặc giữ nguyên
      walletIds: walletIds ?? this.walletIds,

      tags: tags ?? this.tags,

      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      // Xóa hoặc giữ / cập nhật transactionType
    );
  }

  FilterOptions reset() {
    // Reset toàn bộ bộ lọc
    return FilterOptions();
    // Trả về FilterOptions mới với giá trị mặc định
  }
}

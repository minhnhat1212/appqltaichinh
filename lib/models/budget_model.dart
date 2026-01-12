import 'package:cloud_firestore/cloud_firestore.dart'; // Import thư viện Firestore để làm việc với database Firebase

class BudgetModel {
  // Khai báo class BudgetModel – đại diện cho một ngân sách

  final String id; // ID duy nhất của ngân sách (documentId trong Firestore)
  final String userId; // ID của người dùng sở hữu ngân sách
  final String name; // Tên ngân sách (vd: Ăn uống, Mua sắm)
  final double amount; // Số tiền giới hạn của ngân sách
  final String period; // Chu kỳ ngân sách: monthly, weekly, custom
  final String? categoryId; // ID danh mục áp dụng, null nếu áp dụng cho tất cả
  final DateTime startDate; // Ngày bắt đầu ngân sách
  final DateTime endDate; // Ngày kết thúc ngân sách
  final bool isRecurring; // Có tự động lặp lại ngân sách không
  final DateTime createdAt; // Thời điểm tạo ngân sách

  BudgetModel({
    // Constructor của BudgetModel
    required this.id, // Bắt buộc truyền id
    required this.userId, // Bắt buộc truyền userId
    required this.name, // Bắt buộc truyền tên ngân sách
    required this.amount, // Bắt buộc truyền số tiền giới hạn
    required this.period, // Bắt buộc truyền chu kỳ
    this.categoryId, // Không bắt buộc, có thể null
    required this.startDate, // Bắt buộc truyền ngày bắt đầu
    required this.endDate, // Bắt buộc truyền ngày kết thúc
    required this.isRecurring, // Bắt buộc truyền trạng thái lặp
    required this.createdAt, // Bắt buộc truyền thời gian tạo
  });

  Map<String, dynamic> toMap() {
    // Chuyển object BudgetModel thành Map để lưu Firestore
    return {
      'userId': userId, // Lưu userId
      'name': name, // Lưu tên ngân sách
      'amount': amount, // Lưu số tiền giới hạn
      'period': period, // Lưu chu kỳ
      'categoryId': categoryId, // Lưu categoryId (có thể null)
      'startDate': Timestamp.fromDate(startDate), // Chuyển DateTime → Timestamp
      'endDate': Timestamp.fromDate(endDate), // Chuyển DateTime → Timestamp
      'isRecurring': isRecurring, // Lưu trạng thái lặp
      'createdAt': Timestamp.fromDate(createdAt), // Chuyển DateTime → Timestamp
    };
  }

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    // Tạo BudgetModel từ dữ liệu Firestore
    return BudgetModel(
      id: id, // Lấy id từ documentId
      userId: map['userId'] ?? '', // Lấy userId, nếu null thì dùng chuỗi rỗng
      name: map['name'] ?? '', // Lấy name, nếu null thì dùng chuỗi rỗng
      amount: (map['amount'] ?? 0)
          .toDouble(), // Lấy amount, đảm bảo kiểu double
      period: map['period'] ?? 'monthly', // Lấy period, mặc định là monthly
      categoryId: map['categoryId'], // Lấy categoryId (có thể null)
      startDate: (map['startDate'] as Timestamp)
          .toDate(), // Timestamp → DateTime
      endDate: (map['endDate'] as Timestamp).toDate(), // Timestamp → DateTime
      isRecurring:
          map['isRecurring'] ?? false, // Lấy isRecurring, mặc định false
      createdAt: (map['createdAt'] as Timestamp)
          .toDate(), // Timestamp → DateTime
    );
  }

  bool isActive() {
    // Kiểm tra ngân sách có đang hoạt động không
    final now = DateTime.now(); // Lấy thời gian hiện tại
    return now.isAfter(startDate) &&
        now.isBefore(endDate); // Kiểm tra trong khoảng thời gian
  }

  double getProgressPercentage(double spentAmount) {
    // Tính % đã chi
    if (amount == 0) return 0; // Tránh lỗi chia cho 0
    return (spentAmount / amount) * 100; // Công thức tính phần trăm
  }

  double getRemainingAmount(double spentAmount) {
    // Tính số tiền còn lại
    return amount - spentAmount; // Âm = chi vượt, dương = còn tiền
  }

  String getAlertLevel(double spentAmount) {
    // Xác định mức cảnh báo ngân sách
    final percentage = getProgressPercentage(spentAmount); // Lấy % đã chi

    if (percentage >= 100) return 'exceeded'; // Vượt ngân sách
    if (percentage >= 90) return 'danger'; // Nguy hiểm
    if (percentage >= 80) return 'warning'; // Cảnh báo
    return 'safe'; // An toàn
  }

  BudgetModel copyWith({
    // Tạo bản sao BudgetModel với dữ liệu mới
    String? id, // id mới (nếu có)
    String? userId, // userId mới (nếu có)
    String? name, // tên mới (nếu có)
    double? amount, // amount mới (nếu có)
    String? period, // period mới (nếu có)
    String? categoryId, // categoryId mới (nếu có)
    DateTime? startDate, // startDate mới (nếu có)
    DateTime? endDate, // endDate mới (nếu có)
    bool? isRecurring, // isRecurring mới (nếu có)
    DateTime? createdAt, // createdAt mới (nếu có)
  }) {
    return BudgetModel(
      id: id ?? this.id, // Nếu id null thì giữ id cũ
      userId: userId ?? this.userId, // Nếu userId null thì giữ userId cũ
      name: name ?? this.name, // Giữ name cũ nếu không truyền
      amount: amount ?? this.amount, // Giữ amount cũ nếu không truyền
      period: period ?? this.period, // Giữ period cũ nếu không truyền
      categoryId: categoryId ?? this.categoryId, // Giữ categoryId cũ
      startDate: startDate ?? this.startDate, // Giữ startDate cũ
      endDate: endDate ?? this.endDate, // Giữ endDate cũ
      isRecurring: isRecurring ?? this.isRecurring, // Giữ trạng thái cũ
      createdAt: createdAt ?? this.createdAt, // Giữ createdAt cũ
    );
  }
}

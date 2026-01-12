import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore để làm việc với database

/// Model đại diện cho một giao dịch (Transaction)
/// Giao dịch có thể là thu nhập hoặc chi tiêu
class TransactionModel {
  final String id; // ID duy nhất của giao dịch
  final String userId; // ID của user sở hữu giao dịch
  final double amount; // Số tiền của giao dịch (VNĐ)
  final String
  type; // Loại giao dịch: 'income' (thu nhập) hoặc 'expense' (chi tiêu)
  final DateTime date; // Ngày thực hiện giao dịch
  final String? note; // Ghi chú cho giao dịch (tùy chọn)
  final String categoryId; // ID của danh mục
  final String walletId; // ID của ví được sử dụng
  final String? imageUrl; // URL hình ảnh đính kèm (tùy chọn)
  final List<String> tags; // Danh sách các tag/nhãn cho giao dịch

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    required this.categoryId,
    required this.walletId,
    this.imageUrl,
    required this.tags,
  });

  /// Chuyển object thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId, // ID user
      'amount': amount, // Số tiền
      'type': type, // Loại giao dịch
      'date': Timestamp.fromDate(date), // Chuyển DateTime sang Timestamp
      'note': note, // Ghi chú (có thể null)
      'categoryId': categoryId, // ID danh mục
      'walletId': walletId, // ID ví
      'imageUrl': imageUrl, // URL hình ảnh (có thể null)
      'tags': tags, // Danh sách tag
    };
  }

  /// Tạo TransactionModel từ Firestore document
  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id, // Gán ID từ document ID
      userId: map['userId'] ?? '', // Lấy userId, mặc định '' nếu null
      amount: (map['amount'] ?? 0).toDouble(), // Lấy amount, chuyển sang double
      type: map['type'] ?? 'expense', // Lấy type, mặc định 'expense'
      date: (map['date'] as Timestamp)
          .toDate(), // Chuyển Timestamp sang DateTime
      note: map['note'], // Lấy note (có thể null)
      categoryId: map['categoryId'] ?? '', // Lấy categoryId, mặc định ''
      walletId: map['walletId'] ?? '', // Lấy walletId, mặc định ''
      imageUrl: map['imageUrl'], // Lấy imageUrl (có thể null)
      tags: List<String>.from(
        map['tags'] ?? [],
      ), // Chuyển dynamic list thành List<String>
    );
  }
}

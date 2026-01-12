import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore để làm việc với database

/// Model đại diện cho một mục tiêu tiết kiệm (Savings Goal)
/// Giúp người dùng đặt mục tiêu tiết kiệm và theo dõi tiến độ
class SavingsGoalModel {
  final String id; // ID duy nhất của mục tiêu
  final String userId; // ID của user sở hữu mục tiêu
  final String name; // Tên mục tiêu (VD: "Mua iPhone 15", "Du lịch Nhật Bản")
  final double targetAmount; // Số tiền mục tiêu cần đạt được (VNĐ)
  final double currentAmount; // Số tiền đã góp vào mục tiêu (VNĐ)
  final DateTime deadline; // Hạn chót để hoàn thành mục tiêu
  final String
  iconName; // Tên icon để hiển thị (VD: 'savings', 'flight', 'home')
  final String color; // Màu sắc hiển thị (hex string, VD: 'FF6B4EFF')
  final String? description; // Mô tả chi tiết về mục tiêu (tùy chọn)
  final DateTime createdAt; // Ngày tạo mục tiêu
  final DateTime updatedAt; // Ngày cập nhật mục tiêu lần cuối

  SavingsGoalModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.iconName,
    required this.color,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Chuyển object thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId, // ID user
      'name': name, // Tên mục tiêu
      'targetAmount': targetAmount, // Số tiền mục tiêu
      'currentAmount': currentAmount, // Số tiền hiện tại
      'deadline': Timestamp.fromDate(
        deadline,
      ), // Chuyển DateTime sang Timestamp
      'iconName': iconName, // Icon
      'color': color, // Màu sắc
      'description': description, // Mô tả (có thể null)
      'createdAt': Timestamp.fromDate(
        createdAt,
      ), // Chuyển DateTime sang Timestamp
      'updatedAt': Timestamp.fromDate(
        updatedAt,
      ), // Chuyển DateTime sang Timestamp
    };
  }

  /// Tạo SavingsGoalModel từ Firestore document
  factory SavingsGoalModel.fromMap(String id, Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: id, // Gán ID từ document ID
      userId: map['userId'] ?? '', // Lấy userId, mặc định ''
      name: map['name'] ?? '', // Lấy name, mặc định ''
      targetAmount: (map['targetAmount'] ?? 0)
          .toDouble(), // Lấy targetAmount, chuyển sang double
      currentAmount: (map['currentAmount'] ?? 0)
          .toDouble(), // Lấy currentAmount, chuyển sang double
      deadline: (map['deadline'] as Timestamp)
          .toDate(), // Chuyển Timestamp sang DateTime
      iconName:
          map['iconName'] ?? 'savings', // Lấy iconName, mặc định 'savings'
      color: map['color'] ?? 'FF6B4EFF', // Lấy color, mặc định 'FF6B4EFF'
      description: map['description'], // Lấy description (có thể null)
      createdAt: (map['createdAt'] as Timestamp)
          .toDate(), // Chuyển Timestamp sang DateTime
      updatedAt: (map['updatedAt'] as Timestamp)
          .toDate(), // Chuyển Timestamp sang DateTime
    );
  }

  /// Tính phần trăm tiến độ đã đạt được
  /// Công thức: (hiện tại / mục tiêu) * 100
  double getProgressPercentage() {
    if (targetAmount == 0) return 0; // Tránh chia cho 0
    return (currentAmount / targetAmount) *
        100; // Tính phần trăm (có thể > 100 nếu vượt mục tiêu)
  }

  /// Tính số tiền còn thiếu để đạt mục tiêu
  /// Công thức: mục tiêu - hiện tại
  double getRemainingAmount() {
    return targetAmount - currentAmount; // Kết quả âm = đã vượt mục tiêu
  }

  /// Tính số ngày còn lại đến hạn chót
  int getDaysRemaining() {
    final now = DateTime.now(); // Lấy thời gian hiện tại
    final difference = deadline.difference(now); // Tính khoảng cách thời gian
    return difference.inDays; // Trả về số ngày (có thể âm nếu đã quá hạn)
  }

  /// Kiểm tra xem mục tiêu đã hoàn thành chưa
  /// Return: true nếu số tiền hiện tại >= số tiền mục tiêu
  bool isCompleted() {
    return currentAmount >= targetAmount;
  }

  /// Kiểm tra xem mục tiêu có quá hạn không
  /// Return: true nếu đã quá hạn chót và chưa hoàn thành
  bool isOverdue() {
    final now = DateTime.now(); // Lấy thời gian hiện tại
    return now.isAfter(deadline) &&
        !isCompleted(); // Quá hạn = sau deadline và chưa hoàn thành
  }

  /// Xác định trạng thái của mục tiêu
  /// Return: 'completed', 'overdue', 'on_track', hoặc 'behind'
  String getStatus() {
    if (isCompleted()) return 'completed'; // Đã hoàn thành
    if (isOverdue()) return 'overdue'; // Quá hạn

    final progressPercentage =
        getProgressPercentage(); // Tính phần trăm tiến độ thực tế
    final totalDays = deadline
        .difference(createdAt)
        .inDays; // Tổng số ngày từ lúc tạo đến deadline
    final daysPassed = DateTime.now()
        .difference(createdAt)
        .inDays; // Số ngày đã trải qua
    final expectedProgress = totalDays > 0
        ? (daysPassed / totalDays) * 100
        : 0; // Phần trăm thời gian đã trôi qua

    // Nếu tiến độ thực tế >= 80% tiến độ dự kiến thì coi là đúng tiến độ
    if (progressPercentage >= expectedProgress * 0.8) {
      return 'on_track'; // Đúng tiến độ
    } else {
      return 'behind'; // Chậm tiến độ
    }
  }

  /// Tạo bản sao SavingsGoalModel với một số trường được cập nhật
  /// Các trường không truyền vào sẽ giữ nguyên giá trị cũ
  SavingsGoalModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? iconName,
    String? color,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id, // Dùng giá trị mới nếu có, không thì giữ giá trị cũ
      userId:
          userId ??
          this.userId, // Toán tử ?? = nếu null thì dùng giá trị bên phải
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

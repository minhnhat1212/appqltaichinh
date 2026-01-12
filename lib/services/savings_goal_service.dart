import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/savings_goal_model.dart'; // Import SavingsGoalModel

/// Service quản lý mục tiêu tiết kiệm (Savings Goal)
/// Xử lý CRUD operations, contributions, và statistics
class SavingsGoalService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore

  // ==================== CRUD Operations ====================

  /// Thêm mục tiêu tiết kiệm mới
  Future<void> addGoal(SavingsGoalModel goal) async {
    final docRef = _firestore
        .collection('savings_goals')
        .doc(); // Tạo document với ID tự động
    final goalData = goal.toMap();
    goalData['id'] = docRef.id; // Thêm ID vào data
    await docRef.set(goalData);
  }

  /// Cập nhật mục tiêu tiết kiệm
  /// Tự động cập nhật updatedAt timestamp
  Future<void> updateGoal(SavingsGoalModel goal) async {
    final updatedGoal = goal.copyWith(
      updatedAt: DateTime.now(),
    ); // Cập nhật updatedAt
    await _firestore
        .collection('savings_goals')
        .doc(goal.id)
        .update(updatedGoal.toMap());
  }

  /// Xóa mục tiêu tiết kiệm
  /// Xóa cả tất cả contributions của mục tiêu
  Future<void> deleteGoal(String goalId) async {
    // Xóa tất cả contributions trước
    final contributionsSnapshot = await _firestore
        .collection('savings_goals')
        .doc(goalId)
        .collection('contributions')
        .get();

    final batch = _firestore.batch();
    for (var doc in contributionsSnapshot.docs) {
      batch.delete(doc.reference); // Thêm vào batch
    }

    // Xóa goal
    batch.delete(_firestore.collection('savings_goals').doc(goalId));
    await batch.commit(); // Commit tất cả thay đổi cùng lúc
  }

  /// Lấy tất cả mục tiêu tiết kiệm của user (Real-time Stream)
  Stream<List<SavingsGoalModel>> getGoals(String userId) {
    return _firestore
        .collection('savings_goals')
        .where('userId', isEqualTo: userId)
        .orderBy(
          'createdAt',
          descending: true,
        ) // Sắp xếp theo ngày tạo mới nhất
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SavingsGoalModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Lấy một mục tiêu cụ thể
  /// Return: SavingsGoalModel hoặc null nếu không tìm thấy
  Future<SavingsGoalModel?> getGoal(String goalId) async {
    final doc = await _firestore.collection('savings_goals').doc(goalId).get();
    if (!doc.exists) return null;
    return SavingsGoalModel.fromMap(doc.id, doc.data()!);
  }

  /// Lấy mục tiêu đang hoạt động (chưa hoàn thành)
  Stream<List<SavingsGoalModel>> getActiveGoals(String userId) {
    return getGoals(
      userId,
    ).map((goals) => goals.where((goal) => !goal.isCompleted()).toList());
  }

  /// Lấy mục tiêu đã hoàn thành
  Stream<List<SavingsGoalModel>> getCompletedGoals(String userId) {
    return getGoals(
      userId,
    ).map((goals) => goals.where((goal) => goal.isCompleted()).toList());
  }

  // ==================== Contribution Operations ====================

  /// Thêm contribution (góp tiền) vào mục tiêu
  /// Tự động cập nhật currentAmount của goal
  Future<void> addContribution({
    required String goalId,
    required double amount,
    String? note,
  }) async {
    final goal = await getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    final batch = _firestore.batch();

    // 1. Thêm contribution record
    final contributionRef = _firestore
        .collection('savings_goals')
        .doc(goalId)
        .collection('contributions')
        .doc(); // Auto generate ID

    batch.set(contributionRef, {
      'amount': amount,
      'note': note,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });

    // 2. Cập nhật currentAmount của goal
    final newCurrentAmount = goal.currentAmount + amount;
    final goalRef = _firestore.collection('savings_goals').doc(goalId);
    batch.update(goalRef, {
      'currentAmount': newCurrentAmount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit(); // Commit tất cả thay đổi cùng lúc
  }

  /// Lấy danh sách contributions của một mục tiêu (Real-time Stream)
  Stream<List<Map<String, dynamic>>> getContributions(String goalId) {
    return _firestore
        .collection('savings_goals')
        .doc(goalId)
        .collection('contributions')
        .orderBy('createdAt', descending: true) // Sắp xếp theo ngày mới nhất
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'amount': (data['amount'] ?? 0).toDouble(),
              'note': data['note'],
              'createdAt': (data['createdAt'] as Timestamp).toDate(),
            };
          }).toList(),
        );
  }

  /// Xóa một contribution
  /// Tự động trừ currentAmount của goal
  Future<void> deleteContribution({
    required String goalId,
    required String contributionId,
    required double amount,
  }) async {
    final goal = await getGoal(goalId);
    if (goal == null) {
      throw Exception('Goal not found');
    }

    final batch = _firestore.batch();

    // 1. Xóa contribution record
    final contributionRef = _firestore
        .collection('savings_goals')
        .doc(goalId)
        .collection('contributions')
        .doc(contributionId);
    batch.delete(contributionRef);

    // 2. Cập nhật currentAmount của goal (trừ đi amount)
    final newCurrentAmount = (goal.currentAmount - amount).clamp(
      0.0, // Không cho âm
      double.infinity,
    );
    final goalRef = _firestore.collection('savings_goals').doc(goalId);
    batch.update(goalRef, {
      'currentAmount': newCurrentAmount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  // ==================== Statistics ====================

  /// Tính tổng số tiền đã tiết kiệm của user (tất cả goals)
  Future<double> getTotalSavedAmount(String userId) async {
    final snapshot = await _firestore
        .collection('savings_goals')
        .where('userId', isEqualTo: userId)
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final goal = SavingsGoalModel.fromMap(doc.id, doc.data());
      total += goal.currentAmount; // Cộng dồn currentAmount
    }

    return total;
  }

  /// Đếm số mục tiêu đã hoàn thành
  Future<int> getCompletedGoalsCount(String userId) async {
    final snapshot = await _firestore
        .collection('savings_goals')
        .where('userId', isEqualTo: userId)
        .get();

    int count = 0;
    for (var doc in snapshot.docs) {
      final goal = SavingsGoalModel.fromMap(doc.id, doc.data());
      if (goal.isCompleted()) count++; // Đếm goals đã hoàn thành
    }

    return count;
  }
}

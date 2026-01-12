import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/budget_model.dart'; // Import BudgetModel
import '../models/transaction_model.dart'; // Import TransactionModel

/// Service quản lý ngân sách (Budget)
/// Xử lý CRUD operations, tính toán số tiền đã chi, alerts, và recurring budgets
class BudgetService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore

  // ==================== CRUD Operations ====================

  /// Thêm ngân sách mới
  Future<void> addBudget(BudgetModel budget) async {
    final docRef = _firestore
        .collection('budgets')
        .doc(); // Tạo document với ID tự động
    final budgetData = budget.toMap();
    budgetData['id'] = docRef.id; // Thêm ID vào data
    await docRef.set(budgetData);
  }

  /// Cập nhật ngân sách
  Future<void> updateBudget(BudgetModel budget) async {
    await _firestore
        .collection('budgets')
        .doc(budget.id)
        .update(budget.toMap());
  }

  /// Xóa ngân sách
  Future<void> deleteBudget(String budgetId) async {
    await _firestore.collection('budgets').doc(budgetId).delete();
  }

  /// Lấy tất cả ngân sách của user (Real-time Stream)
  Stream<List<BudgetModel>> getBudgets(String userId) {
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .orderBy(
          'createdAt',
          descending: true,
        ) // Sắp xếp theo ngày tạo mới nhất
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BudgetModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Lấy ngân sách đang hoạt động (chưa hết hạn)
  Stream<List<BudgetModel>> getActiveBudgets(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .where(
          'endDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(now),
        ) // Chưa hết hạn
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BudgetModel.fromMap(doc.id, doc.data()))
              .where((budget) {
                // Filter client-side: startDate phải <= now
                return budget.startDate.isBefore(now) ||
                    budget.startDate.isAtSameMomentAs(now);
              })
              .toList(),
        );
  }

  // ==================== Calculation Methods ====================

  /// Tính số tiền đã chi cho một ngân sách
  /// Sử dụng danh sách transactions đã có sẵn (nhanh hơn query Firestore)
  Future<double> calculateSpentAmount(
    BudgetModel budget,
    List<TransactionModel> allTransactions,
  ) async {
    double total = 0;

    for (var transaction in allTransactions) {
      if (transaction.type != 'expense') continue; // Chỉ tính expense

      // Kiểm tra giao dịch có nằm trong khoảng thời gian ngân sách không
      if (transaction.date.isBefore(budget.startDate) ||
          transaction.date.isAfter(budget.endDate)) {
        continue;
      }

      // Nếu ngân sách cho category cụ thể, chỉ tính giao dịch của category đó
      if (budget.categoryId != null &&
          transaction.categoryId != budget.categoryId) {
        continue;
      }

      total += transaction.amount;
    }

    return total;
  }

  /// Lấy số tiền đã chi trực tiếp từ Firestore (alternative method)
  /// Chậm hơn calculateSpentAmount nhưng không cần danh sách transactions
  Future<double> getSpentAmountFromFirestore(BudgetModel budget) async {
    var query = _firestore
        .collection('transactions')
        .where('userId', isEqualTo: budget.userId)
        .where('type', isEqualTo: 'expense')
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(budget.startDate),
        )
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(budget.endDate));

    final snapshot = await query.get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final transaction = TransactionModel.fromMap(doc.id, doc.data());

      // Filter theo category nếu có
      if (budget.categoryId != null &&
          transaction.categoryId != budget.categoryId) {
        continue;
      }

      total += transaction.amount;
    }

    return total;
  }

  // ==================== Alert Methods ====================

  /// Kiểm tra alerts cho tất cả ngân sách của user
  /// Return: Danh sách ngân sách có cảnh báo (warning, danger, exceeded)
  Future<List<Map<String, dynamic>>> checkBudgetAlerts(String userId) async {
    final alerts = <Map<String, dynamic>>[];

    final budgetsSnapshot = await _firestore
        .collection('budgets')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in budgetsSnapshot.docs) {
      final budget = BudgetModel.fromMap(doc.id, doc.data());

      if (!budget.isActive()) continue; // Bỏ qua ngân sách không hoạt động

      final spentAmount = await getSpentAmountFromFirestore(
        budget,
      ); // Tính số tiền đã chi
      final alertLevel = budget.getAlertLevel(
        spentAmount,
      ); // Lấy mức độ cảnh báo

      // Chỉ thêm alerts cho warning, danger, hoặc exceeded
      if (alertLevel != 'safe') {
        alerts.add({
          'budget': budget,
          'spentAmount': spentAmount,
          'alertLevel': alertLevel,
          'percentage': budget.getProgressPercentage(spentAmount),
        });
      }
    }

    return alerts;
  }

  // ==================== Recurring Budget Methods ====================

  /// Tạo ngân sách mới cho chu kỳ tiếp theo (recurring budgets)
  /// Tự động tạo ngân sách tháng/tuần tiếp theo khi ngân sách hiện tại hết hạn
  Future<void> createRecurringBudgets() async {
    final now = DateTime.now();

    // Tìm ngân sách đã hết hạn và có isRecurring = true
    final budgetsSnapshot = await _firestore
        .collection('budgets')
        .where('isRecurring', isEqualTo: true)
        .where('endDate', isLessThan: Timestamp.fromDate(now))
        .get();

    final batch = _firestore.batch();

    for (var doc in budgetsSnapshot.docs) {
      final oldBudget = BudgetModel.fromMap(doc.id, doc.data());

      // Tính toán khoảng thời gian cho chu kỳ tiếp theo
      DateTime newStartDate;
      DateTime newEndDate;

      if (oldBudget.period == 'monthly') {
        // Ngân sách theo tháng
        newStartDate = DateTime(
          oldBudget.endDate.year,
          oldBudget.endDate.month + 1,
          1,
        );
        newEndDate = DateTime(
          newStartDate.year,
          newStartDate.month + 1,
          0, // Ngày cuối tháng
          23,
          59,
          59,
        );
      } else if (oldBudget.period == 'weekly') {
        // Ngân sách theo tuần
        newStartDate = oldBudget.endDate.add(const Duration(days: 1));
        newEndDate = newStartDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
      } else {
        continue; // Bỏ qua custom budgets
      }

      // Tạo ngân sách mới cho chu kỳ tiếp theo
      final newBudgetRef = _firestore.collection('budgets').doc();
      final newBudget = oldBudget.copyWith(
        id: newBudgetRef.id,
        startDate: newStartDate,
        endDate: newEndDate,
        createdAt: now,
      );

      batch.set(newBudgetRef, newBudget.toMap());
    }

    await batch.commit();
  }

  // ==================== Helper Methods ====================

  /// Lấy ngày bắt đầu và kết thúc cho một period (để tạo ngân sách nhanh)
  /// Return: Map chứa startDate và endDate
  static Map<String, DateTime> getPeriodDates(String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (period) {
      case 'monthly': // Tháng hiện tại
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'weekly': // Tuần hiện tại (bắt đầu từ thứ 2)
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      default: // Custom - 30 ngày từ hôm nay
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(
          const Duration(days: 29, hours: 23, minutes: 59, seconds: 59),
        );
    }

    return {'startDate': startDate, 'endDate': endDate};
  }

  // ==================== PERFORMANCE OPTIMIZATION ====================

  /// Stream số tiền đã chi cho nhiều ngân sách cùng lúc
  /// Loại bỏ O(n²) complexity khi tính trong ListView builder
  Stream<Map<String, double>> getBudgetSpentAmounts(
    String userId,
    List<BudgetModel> budgets,
  ) async* {
    if (budgets.isEmpty) {
      yield {};
      return;
    }

    // Lắng nghe transactions stream
    await for (final transactions
        in _firestore
            .collection('transactions')
            .where('userId', isEqualTo: userId)
            .where('type', isEqualTo: 'expense')
            .snapshots()) {
      final transactionModels = transactions.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();

      // Tính số tiền đã chi cho từng ngân sách
      final spentAmounts = <String, double>{};

      for (var budget in budgets) {
        double total = 0;

        for (var transaction in transactionModels) {
          // Kiểm tra giao dịch có nằm trong khoảng thời gian ngân sách không
          if (transaction.date.isBefore(budget.startDate) ||
              transaction.date.isAfter(budget.endDate)) {
            continue;
          }

          // Nếu ngân sách cho category cụ thể, chỉ tính giao dịch của category đó
          if (budget.categoryId != null &&
              transaction.categoryId != budget.categoryId) {
            continue;
          }

          total += transaction.amount;
        }

        spentAmounts[budget.id] = total; // Lưu kết quả
      }

      yield spentAmounts; // Emit kết quả
    }
  }
}

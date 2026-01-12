import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/transaction_model.dart'; // Import TransactionModel
import '../models/category_model.dart'; // Import CategoryModel
import '../models/wallet_model.dart'; // Import WalletModel

/// Service quản lý giao dịch (Transaction)
/// Xử lý CRUD operations, cập nhật số dư ví, và quản lý categories
class TransactionService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore

  // Cache cho transactions với TTL (Time To Live)
  final Map<String, List<TransactionModel>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  void clearCache() {
    _cache.clear(); // Xóa cache transactions
    _cacheTimestamps.clear(); // Xóa timestamps
  }

  /// Thêm giao dịch mới và cập nhật số dư ví
  /// Sử dụng batch để đảm bảo atomic (cả 2 operations thành công hoặc cả 2 fail)
  Future<void> addTransaction(TransactionModel transaction) async {
    final batch = _firestore
        .batch(); // Tạo batch để ghi nhiều operations cùng lúc

    // 1. Tạo Transaction Document
    final transactionRef = _firestore
        .collection('transactions')
        .doc(); // Auto generate ID
    final transactionData = transaction.toMap();
    transactionData['id'] = transactionRef.id; // Thêm ID vào data
    batch.set(transactionRef, transactionData);

    // 2. Cập nhật số dư ví (sử dụng subcollection path)
    final walletRef = _firestore
        .collection('users')
        .doc(transaction.userId)
        .collection('wallets')
        .doc(transaction.walletId);

    // Logic: Income tăng số dư, Expense giảm số dư
    double amountChange = transaction.amount;
    if (transaction.type == 'expense') {
      amountChange = -amountChange; // Expense = số âm
    }

    batch.update(walletRef, {
      'balance': FieldValue.increment(amountChange),
    }); // Increment atomic

    await batch.commit(); // Commit tất cả thay đổi cùng lúc
  }

  /// Xóa giao dịch và hoàn lại số dư ví
  Future<void> deleteTransaction(TransactionModel transaction) async {
    final batch = _firestore.batch();

    // 1. Xóa Document
    final transactionRef = _firestore
        .collection('transactions')
        .doc(transaction.id);
    batch.delete(transactionRef);

    // 2. Hoàn lại số dư ví (reverse logic)
    final walletRef = _firestore
        .collection('users')
        .doc(transaction.userId)
        .collection('wallets')
        .doc(transaction.walletId);

    // Reverse logic: Income -> Trừ đi, Expense -> Cộng lại
    double amountChange = transaction.amount;
    if (transaction.type == 'expense') {
      amountChange = amountChange; // Expense đã trừ, giờ cộng lại
    } else {
      amountChange = -amountChange; // Income đã cộng, giờ trừ đi
    }

    batch.update(walletRef, {'balance': FieldValue.increment(amountChange)});

    await batch.commit();
  }

  /// Cập nhật giao dịch và điều chỉnh số dư ví
  /// Xử lý cả trường hợp đổi ví và trường hợp cùng ví
  Future<void> updateTransaction(
    TransactionModel oldTransaction,
    TransactionModel newTransaction,
  ) async {
    final batch = _firestore.batch();
    final transactionRef = _firestore
        .collection('transactions')
        .doc(oldTransaction.id);

    // 1. Cập nhật Document
    batch.update(transactionRef, newTransaction.toMap());

    // 2. Điều chỉnh số dư
    if (oldTransaction.walletId != newTransaction.walletId) {
      // Trường hợp đổi ví: Hoàn lại ví cũ, áp dụng cho ví mới
      final oldWalletRef = _firestore
          .collection('users')
          .doc(oldTransaction.userId)
          .collection('wallets')
          .doc(oldTransaction.walletId);
      double oldRevert = oldTransaction.type == 'expense'
          ? oldTransaction
                .amount // Hoàn lại expense
          : -oldTransaction.amount; // Hoàn lại income
      batch.update(oldWalletRef, {'balance': FieldValue.increment(oldRevert)});

      // Áp dụng cho ví mới
      final newWalletRef = _firestore
          .collection('users')
          .doc(newTransaction.userId)
          .collection('wallets')
          .doc(newTransaction.walletId);
      double newApply = newTransaction.type == 'expense'
          ? -newTransaction.amount
          : newTransaction.amount;
      batch.update(newWalletRef, {'balance': FieldValue.increment(newApply)});
    } else {
      // Trường hợp cùng ví: Chỉ cần tính chênh lệch
      double oldVal = oldTransaction.type == 'expense'
          ? -oldTransaction.amount
          : oldTransaction.amount;
      double newVal = newTransaction.type == 'expense'
          ? -newTransaction.amount
          : newTransaction.amount;
      double diff = newVal - oldVal; // Chênh lệch cần điều chỉnh

      if (diff != 0) {
        final walletRef = _firestore
            .collection('users')
            .doc(oldTransaction.userId)
            .collection('wallets')
            .doc(oldTransaction.walletId);
        batch.update(walletRef, {'balance': FieldValue.increment(diff)});
      }
    }

    await batch.commit();
  }

  /// Lấy danh sách giao dịch của user (Real-time Stream)
  /// Giới hạn 100 giao dịch gần nhất để tối ưu performance
  Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true) // Sắp xếp theo ngày mới nhất
        .limit(100) // Giới hạn 100 giao dịch
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Lấy giao dịch gần đây với pagination
  /// Tối ưu hơn cho danh sách dài
  Stream<List<TransactionModel>> getRecentTransactions(
    String userId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit) // Giới hạn số lượng
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Lấy giao dịch trong một khoảng thời gian cụ thể
  /// Dùng để tính toán thống kê theo period
  Stream<List<TransactionModel>> getTransactionsForPeriod(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        // Lọc theo date range trực tiếp trên Firestore
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Lấy danh sách ví (DEPRECATED - Dùng WalletService.getWallets() thay thế)
  @Deprecated('Use WalletService.getWallets() instead')
  Stream<List<WalletModel>> getWallets(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WalletModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Lấy danh sách categories (global)
  Stream<List<CategoryModel>> getCategories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Khởi tạo categories mặc định nếu chưa có
  Future<void> initDefaultCategories() async {
    final snap = await _firestore.collection('categories').limit(1).get();
    if (snap.docs.isEmpty) {
      final batch = _firestore
          .batch(); // Sử dụng batch để tạo nhiều categories cùng lúc

      final categories = [
        {'name': 'Ăn uống', 'type': 'expense', 'icon': 'restaurant'},
        {'name': 'Di chuyển', 'type': 'expense', 'icon': 'directions_car'},
        {'name': 'Mua sắm', 'type': 'expense', 'icon': 'shopping_cart'},
        {'name': 'Lương', 'type': 'income', 'icon': 'attach_money'},
        {'name': 'Thưởng', 'type': 'income', 'icon': 'card_giftcard'},
      ];

      for (var c in categories) {
        final docRef = _firestore.collection('categories').doc();
        batch.set(docRef, c);
      }

      await batch.commit();
    }
  }

  /// Thêm category mới
  Future<void> addCategory(CategoryModel category) async {
    await _firestore.collection('categories').add(category.toMap());
  }

  /// Cập nhật category
  Future<void> updateCategory(CategoryModel category) async {
    await _firestore
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  /// Xóa category
  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }
}

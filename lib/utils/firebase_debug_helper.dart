import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore để truy vấn database
import 'dart:developer' as developer; // Import developer để log debug

/// Utility class để debug và kiểm tra dữ liệu Firebase Firestore
/// Giúp dev dễ dàng xem và kiểm tra dữ liệu trong database
class FirebaseDebugHelper {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore

  /// In tất cả users trong database
  /// Bao gồm cả thông tin wallets của từng user
  Future<void> printAllUsers() async {
    try {
      developer.log('=== DANH SÁCH TẤT CẢ USERS ===', name: 'FirebaseDebug');
      final snapshot = await _firestore
          .collection('users')
          .get(); // Lấy tất cả users

      if (snapshot.docs.isEmpty) {
        developer.log(
          'Không có user nào trong database',
          name: 'FirebaseDebug',
        );
        return;
      }

      for (var doc in snapshot.docs) {
        developer.log('User ID: ${doc.id}', name: 'FirebaseDebug');
        developer.log('Data: ${doc.data()}', name: 'FirebaseDebug');

        final walletsSnapshot = await doc.reference
            .collection('wallets')
            .get(); // Lấy wallets của user
        developer.log(
          '  → Wallets (${walletsSnapshot.docs.length}):',
          name: 'FirebaseDebug',
        );
        for (var wallet in walletsSnapshot.docs) {
          developer.log(
            '    - ${wallet.id}: ${wallet.data()}',
            name: 'FirebaseDebug',
          );
        }
        developer.log('', name: 'FirebaseDebug');
      }
    } catch (e) {
      developer.log('Lỗi khi lấy users: $e', name: 'FirebaseDebug', error: e);
    }
  }

  /// In thông tin chi tiết của một user cụ thể
  /// Bao gồm user data và danh sách wallets
  Future<void> printUserDetails(String userId) async {
    try {
      developer.log('=== THÔNG TIN USER: $userId ===', name: 'FirebaseDebug');

      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(); // Lấy user document
      if (!userDoc.exists) {
        developer.log('User không tồn tại', name: 'FirebaseDebug');
        return;
      }

      developer.log('User Data: ${userDoc.data()}', name: 'FirebaseDebug');

      final walletsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .get(); // Lấy wallets của user

      developer.log(
        '\nWallets (${walletsSnapshot.docs.length}):',
        name: 'FirebaseDebug',
      );
      for (var wallet in walletsSnapshot.docs) {
        developer.log(
          '  ${wallet.id}: ${wallet.data()}',
          name: 'FirebaseDebug',
        );
      }
    } catch (e) {
      developer.log('Lỗi: $e', name: 'FirebaseDebug', error: e);
    }
  }

  /// In tất cả transactions của một user
  /// Có thể giới hạn số lượng bằng tham số limit
  Future<void> printUserTransactions(String userId, {int? limit}) async {
    try {
      developer.log(
        '=== TRANSACTIONS CỦA USER: $userId ===',
        name: 'FirebaseDebug',
      );

      var query = _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId) // Lọc theo userId
          .orderBy('date', descending: true); // Sắp xếp theo ngày mới nhất

      if (limit != null) {
        query = query.limit(limit); // Giới hạn số lượng kết quả
      }

      final snapshot = await query.get();
      developer.log(
        'Tổng số transactions: ${snapshot.docs.length}',
        name: 'FirebaseDebug',
      );

      for (var doc in snapshot.docs) {
        final data = doc.data();
        developer.log(
          '${doc.id}: ${data['type']} - ${data['amount']} - ${data['description']} - ${data['date']}',
          name: 'FirebaseDebug',
        );
      }
    } catch (e) {
      developer.log('Lỗi: $e', name: 'FirebaseDebug', error: e);
    }
  }

  /// In tất cả budgets của một user
  /// Sắp xếp theo ngày tạo mới nhất
  Future<void> printUserBudgets(String userId) async {
    try {
      developer.log('=== BUDGETS CỦA USER: $userId ===', name: 'FirebaseDebug');

      final snapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId) // Lọc theo userId
          .orderBy('createdAt', descending: true) // Sắp xếp theo ngày tạo
          .get();

      developer.log(
        'Tổng số budgets: ${snapshot.docs.length}',
        name: 'FirebaseDebug',
      );

      for (var doc in snapshot.docs) {
        developer.log('${doc.id}: ${doc.data()}', name: 'FirebaseDebug');
      }
    } catch (e) {
      developer.log('Lỗi: $e', name: 'FirebaseDebug', error: e);
    }
  }

  /// In tất cả savings goals của một user
  /// Bao gồm cả số lượng contributions của từng goal
  Future<void> printUserSavingsGoals(String userId) async {
    try {
      developer.log(
        '=== SAVINGS GOALS CỦA USER: $userId ===',
        name: 'FirebaseDebug',
      );

      final snapshot = await _firestore
          .collection('savings_goals')
          .where('userId', isEqualTo: userId) // Lọc theo userId
          .orderBy('createdAt', descending: true) // Sắp xếp theo ngày tạo
          .get();

      developer.log(
        'Tổng số goals: ${snapshot.docs.length}',
        name: 'FirebaseDebug',
      );

      for (var doc in snapshot.docs) {
        final data = doc.data();
        developer.log('${doc.id}: $data', name: 'FirebaseDebug');

        final contributionsSnapshot = await doc.reference
            .collection('contributions')
            .get(); // Lấy contributions của goal
        developer.log(
          '  → Contributions: ${contributionsSnapshot.docs.length}',
          name: 'FirebaseDebug',
        );
      }
    } catch (e) {
      developer.log('Lỗi: $e', name: 'FirebaseDebug', error: e);
    }
  }

  /// In tất cả categories trong database
  Future<void> printAllCategories() async {
    try {
      developer.log('=== DANH SÁCH CATEGORIES ===', name: 'FirebaseDebug');

      final snapshot = await _firestore
          .collection('categories')
          .get(); // Lấy tất cả categories
      developer.log(
        'Tổng số categories: ${snapshot.docs.length}',
        name: 'FirebaseDebug',
      );

      for (var doc in snapshot.docs) {
        developer.log('${doc.id}: ${doc.data()}', name: 'FirebaseDebug');
      }
    } catch (e) {
      developer.log('Lỗi: $e', name: 'FirebaseDebug', error: e);
    }
  }

  /// In thống kê tổng quan database
  /// Hiển thị số lượng documents trong mỗi collection
  Future<void> printDatabaseStats() async {
    try {
      developer.log('=== THỐNG KÊ DATABASE ===', name: 'FirebaseDebug');

      final usersCount =
          (await _firestore.collection('users').get()).docs.length; // Đếm users
      final transactionsCount =
          (await _firestore.collection('transactions').get())
              .docs
              .length; // Đếm transactions
      final budgetsCount = (await _firestore.collection('budgets').get())
          .docs
          .length; // Đếm budgets
      final goalsCount = (await _firestore.collection('savings_goals').get())
          .docs
          .length; // Đếm savings goals
      final categoriesCount = (await _firestore.collection('categories').get())
          .docs
          .length; // Đếm categories

      developer.log('Users: $usersCount', name: 'FirebaseDebug');
      developer.log('Transactions: $transactionsCount', name: 'FirebaseDebug');
      developer.log('Budgets: $budgetsCount', name: 'FirebaseDebug');
      developer.log('Savings Goals: $goalsCount', name: 'FirebaseDebug');
      developer.log('Categories: $categoriesCount', name: 'FirebaseDebug');
    } catch (e) {
      developer.log('Lỗi: $e', name: 'FirebaseDebug', error: e);
    }
  }

  /// In tất cả dữ liệu của một user (tổng hợp)
  /// Gọi tất cả các phương thức print khác để hiển thị đầy đủ thông tin
  Future<void> printAllUserData(String userId) async {
    developer.log('\n${'='.padRight(50, '=')}', name: 'FirebaseDebug');
    developer.log('DỮ LIỆU ĐẦY ĐỦ CỦA USER: $userId', name: 'FirebaseDebug');
    developer.log('${'='.padRight(50, '=')}\n', name: 'FirebaseDebug');

    await printUserDetails(userId); // In thông tin user
    await printUserTransactions(userId); // In transactions
    await printUserBudgets(userId); // In budgets
    await printUserSavingsGoals(userId); // In savings goals
  }
}

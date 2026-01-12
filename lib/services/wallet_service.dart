import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import '../models/wallet_model.dart'; // Import WalletModel

/// Service quản lý ví (Wallet)
/// Xử lý CRUD operations và cập nhật số dư
class WalletService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore

  /// Lấy danh sách ví của người dùng (Real-time Stream)
  /// Return: Stream danh sách WalletModel, tự động cập nhật khi có thay đổi
  Stream<List<WalletModel>> getWallets(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .snapshots() // Lắng nghe thay đổi real-time
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => WalletModel.fromMap(doc.id, doc.data()),
              ) // Chuyển đổi từng document thành WalletModel
              .toList(),
        );
  }

  /// Tạo ví mới
  Future<void> createWallet({
    required String userId,
    required String name,
    required String icon,
    required double initialBalance,
  }) async {
    await _firestore.collection('users').doc(userId).collection('wallets').add({
      'name': name,
      'icon': icon,
      'balance': initialBalance,
      'createdAt': FieldValue.serverTimestamp(), // Timestamp tự động từ server
    });
  }

  /// Cập nhật thông tin ví (tên và icon)
  /// Không cập nhật số dư (dùng updateBalance để cập nhật số dư)
  Future<void> updateWallet({
    required String userId,
    required String walletId,
    required String name,
    required String icon,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .update({'name': name, 'icon': icon});
  }

  /// Xóa ví
  /// Lưu ý: Nên kiểm tra xem ví có giao dịch nào không trước khi xóa
  Future<void> deleteWallet({
    required String userId,
    required String walletId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .delete();
  }

  /// Cập nhật số dư ví (sẽ được gọi bởi TransactionService)
  /// Sử dụng FieldValue.increment để cập nhật atomic (tránh race condition)
  Future<void> updateBalance({
    required String userId,
    required String walletId,
    required double amount, // Số tiền thay đổi (dương = tăng, âm = giảm)
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .update({'balance': FieldValue.increment(amount)}); // Increment atomic
  }

  /// Lấy thông tin một ví cụ thể
  /// Return: WalletModel hoặc null nếu không tìm thấy
  Future<WalletModel?> getWallet({
    required String userId,
    required String walletId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .get();

    if (doc.exists) {
      return WalletModel.fromMap(doc.id, doc.data()!);
    }
    return null; // Ví không tồn tại
  }

  /// Khởi tạo ví mặc định khi đăng ký (gọi từ AuthService)
  /// Sử dụng WriteBatch để tạo nhiều ví cùng lúc (nhanh hơn)
  Future<void> initDefaultWallets(String userId) async {
    final batch = _firestore
        .batch(); // Tạo batch để ghi nhiều document cùng lúc

    final wallets = [
      {
        'name': 'Tiền mặt',
        'balance': 0.0,
        'icon': '💰',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Ngân hàng',
        'balance': 0.0,
        'icon': '🏦',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var wallet in wallets) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .doc(); // Tạo document ID tự động
      batch.set(docRef, wallet); // Thêm vào batch
    }

    await batch.commit(); // Commit tất cả thay đổi cùng lúc
  }
}

/// Model đại diện cho một ví/tài khoản (Wallet)
/// Ví được sử dụng để quản lý số dư của các tài khoản khác nhau
class WalletModel {
  final String id; // ID duy nhất của ví
  final String name; // Tên hiển thị của ví (VD: "Tiền mặt", "VCB", "Momo")
  final double balance; // Số dư hiện tại của ví (VNĐ)
  final String
  icon; // Tên icon để hiển thị (VD: 'account_balance_wallet', 'credit_card')

  WalletModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.icon,
  });

  /// Chuyển object thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name, // Tên ví
      'balance': balance, // Số dư hiện tại
      'icon': icon, // Icon ví
    };
  }

  /// Tạo WalletModel từ Firestore document
  factory WalletModel.fromMap(String id, Map<String, dynamic> map) {
    return WalletModel(
      id: id, // Gán ID từ document ID
      name: map['name'] ?? '', // Lấy name, mặc định '' nếu null
      balance: (map['balance'] ?? 0)
          .toDouble(), // Lấy balance, chuyển sang double
      icon: map['icon'] ?? '', // Lấy icon, mặc định '' nếu null
    );
  }
}

/// Model đại diện cho một danh mục giao dịch (Category)
/// Danh mục dùng để phân loại giao dịch thu nhập hoặc chi tiêu
class CategoryModel {
  // Khai báo class CategoryModel

  final String id; // ID duy nhất của danh mục (documentId trong Firestore)
  final String name; // Tên hiển thị của danh mục (VD: "Ăn uống", "Lương")
  final String icon; // Tên icon dùng để hiển thị trên UI
  final String
  type; // Loại danh mục: 'income' (thu nhập) hoặc 'expense' (chi tiêu)

  CategoryModel({
    // Constructor của CategoryModel
    required this.id, // Bắt buộc truyền id
    required this.name, // Bắt buộc truyền tên danh mục
    required this.icon, // Bắt buộc truyền icon
    required this.type, // Bắt buộc truyền loại danh mục
  });

  Map<String, dynamic> toMap() {
    // Chuyển object CategoryModel thành Map để lưu Firestore
    return {
      'name': name, // Lưu tên danh mục
      'icon': icon, // Lưu icon danh mục
      'type': type, // Lưu loại danh mục (income / expense)
    };
  }

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    // Tạo CategoryModel từ dữ liệu Firestore
    return CategoryModel(
      id: id, // Gán id từ documentId của Firestore
      name: map['name'] ?? '', // Lấy name, nếu null thì dùng chuỗi rỗng
      icon: map['icon'] ?? '', // Lấy icon, nếu null thì dùng chuỗi rỗng
      type: map['type'] ?? 'expense', // Lấy type, mặc định là 'expense'
    );
  }
}

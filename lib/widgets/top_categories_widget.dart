import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/statistics_data.dart';

/// Widget hiển thị danh sách top danh mục chi tiêu nhiều nhất
/// Hiển thị thứ hạng, tên danh mục, số tiền, và phần trăm chi tiêu
class TopCategoriesWidget extends StatelessWidget {
  final List<TopCategory> topCategories;

  const TopCategoriesWidget({super.key, required this.topCategories});

  @override
  Widget build(BuildContext context) {
    if (topCategories.isEmpty) { // Kiểm tra nếu danh sách rỗng
      return _buildEmptyState(); // Hiển thị trạng thái rỗng
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), // Margin ngang 16px
      padding: const EdgeInsets.all(20), // Padding tất cả các phía 20px
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng
        borderRadius: BorderRadius.circular(20), // Bo góc 20px
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Màu shadow đen với độ trong suốt 5%
            blurRadius: 15, // Độ mờ shadow
            offset: const Offset(0, 5), // Độ lệch shadow xuống dưới 5px
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Căn trái các phần tử con
        children: [
          Text(
            'Top danh mục chi tiêu', // Tiêu đề
            style: TextStyle(
              fontSize: 18, // Kích thước chữ
              fontWeight: FontWeight.bold, // Chữ đậm
              color: Theme.of(context).primaryColor, // Màu primary của theme
            ),
          ),
          const SizedBox(height: 20), // Khoảng cách dưới tiêu đề
          ...topCategories.map(
            (category) => _buildCategoryItem(context, category), // Duyệt qua từng category và tạo item
          ),
        ],
      ),
    );
  }

  /// Xây dựng một item hiển thị thông tin một danh mục trong top
  /// Bao gồm thứ hạng, icon, tên, số tiền, và thanh tiến độ
  Widget _buildCategoryItem(BuildContext context, TopCategory category) {
    final currencyFormat = NumberFormat.currency(locale: 'vi', symbol: '₫'); // Format tiền tệ VNĐ với ký hiệu ₫

    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // Padding dưới 16px giữa các item
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
        children: [
          Row(
            children: [
              // Rank badge - Huy hiệu hiển thị thứ hạng
              Container(
                width: 32, // Chiều rộng badge
                height: 32, // Chiều cao badge
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor, // Màu primary đậm
                      Theme.of(context).primaryColor.withOpacity(0.7), // Màu primary nhạt hơn (gradient)
                    ],
                  ),
                  shape: BoxShape.circle, // Hình tròn
                ),
                child: Center(
                  child: Text(
                    '${category.rank}', // Hiển thị số thứ hạng
                    style: const TextStyle(
                      color: Colors.white, // Màu chữ trắng
                      fontWeight: FontWeight.bold, // Chữ đậm
                      fontSize: 14, // Kích thước chữ
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12), // Khoảng cách giữa rank và icon
              // Category icon - Icon danh mục
              Container(
                padding: const EdgeInsets.all(8), // Padding 8px
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1), // Nền với màu primary nhạt
                  borderRadius: BorderRadius.circular(10), // Bo góc 10px
                ),
                child: Icon(
                  _getIconData(category.categoryIcon), // Lấy IconData từ tên icon
                  color: Theme.of(context).primaryColor, // Màu icon là primary
                  size: 20, // Kích thước icon 20px
                ),
              ),
              const SizedBox(width: 12), // Khoảng cách giữa icon và thông tin
              // Category name and count - Tên danh mục và số lượng giao dịch
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
                  children: [
                    Text(
                      category.categoryName, // Tên danh mục
                      style: const TextStyle(
                        fontSize: 16, // Kích thước chữ
                        fontWeight: FontWeight.bold, // Chữ đậm
                        color: Colors.black87, // Màu đen nhạt
                      ),
                    ),
                    Text(
                      '${category.transactionCount} giao dịch', // Số lượng giao dịch
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]), // Chữ nhỏ, màu xám
                    ),
                  ],
                ),
              ),
              // Amount - Số tiền chi tiêu
              Text(
                currencyFormat.format(category.amount), // Format số tiền theo VNĐ
                style: TextStyle(
                  fontSize: 16, // Kích thước chữ
                  fontWeight: FontWeight.bold, // Chữ đậm
                  color: Theme.of(context).primaryColor, // Màu primary
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Khoảng cách dưới hàng thông tin
          // Progress bar - Thanh tiến độ hiển thị phần trăm
          ClipRRect(
            borderRadius: BorderRadius.circular(4), // Bo góc 4px
            child: LinearProgressIndicator(
              value: category.percentage / 100, // Giá trị từ 0.0 đến 1.0 (phần trăm / 100)
              backgroundColor: Colors.grey[200], // Màu nền xám nhạt
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor, // Màu thanh tiến độ là primary
              ),
              minHeight: 6, // Chiều cao tối thiểu 6px
            ),
          ),
          const SizedBox(height: 4), // Khoảng cách nhỏ
          Text(
            '${category.percentage.toStringAsFixed(1)}% của tổng chi tiêu', // Hiển thị phần trăm với 1 chữ số thập phân
            style: TextStyle(fontSize: 11, color: Colors.grey[500]), // Chữ nhỏ, màu xám
          ),
        ],
      ),
    );
  }

  /// Chuyển đổi tên icon (string) sang IconData để hiển thị
  /// Trả về Icons.category nếu không tìm thấy icon tương ứng
  IconData _getIconData(String iconName) {
    switch (iconName) { // Kiểm tra tên icon
      case 'restaurant':
        return Icons.restaurant; // Icon nhà hàng
      case 'directions_car':
        return Icons.directions_car; // Icon xe ô tô
      case 'shopping_cart':
        return Icons.shopping_cart; // Icon giỏ hàng
      case 'attach_money':
        return Icons.attach_money; // Icon tiền
      case 'card_giftcard':
        return Icons.card_giftcard; // Icon quà tặng
      case 'home':
        return Icons.home; // Icon nhà
      case 'flight':
        return Icons.flight; // Icon máy bay
      case 'movie':
        return Icons.movie; // Icon phim
      case 'fitness_center':
        return Icons.fitness_center; // Icon phòng gym
      case 'school':
        return Icons.school; // Icon trường học
      default:
        return Icons.category; // Icon mặc định nếu không khớp
    }
  }

  /// Hiển thị trạng thái rỗng khi chưa có dữ liệu
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), // Margin ngang
      padding: const EdgeInsets.all(40), // Padding lớn
      decoration: BoxDecoration(
        color: Colors.white, // Nền trắng
        borderRadius: BorderRadius.circular(20), // Bo góc
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Shadow nhẹ
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.leaderboard, size: 64, color: Colors.grey[300]), // Icon bảng xếp hạng lớn, màu xám nhạt
          const SizedBox(height: 16), // Khoảng cách
          Text(
            'Chưa có dữ liệu', // Thông báo không có dữ liệu
            style: TextStyle(fontSize: 16, color: Colors.grey[600]), // Chữ màu xám
          ),
        ],
      ),
    );
  }
}

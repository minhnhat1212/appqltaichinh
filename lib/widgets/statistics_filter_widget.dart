import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/filter_options.dart';
import '../models/category_model.dart';
import '../models/wallet_model.dart';

/// Widget hiển thị bottom sheet để lọc dữ liệu thống kê
/// Cho phép lọc theo: khoảng thời gian, danh mục, ví, tag, và loại giao dịch
class StatisticsFilterWidget extends StatefulWidget {
  final FilterOptions currentFilters;
  final List<CategoryModel> categories;
  final List<WalletModel> wallets;
  final List<String> availableTags;
  final Function(FilterOptions) onApplyFilters;

  const StatisticsFilterWidget({
    super.key,
    required this.currentFilters,
    required this.categories,
    required this.wallets,
    required this.availableTags,
    required this.onApplyFilters,
  });

  @override
  State<StatisticsFilterWidget> createState() => _StatisticsFilterWidgetState();
}

class _StatisticsFilterWidgetState extends State<StatisticsFilterWidget> {
  late FilterOptions _filters; // Bộ lọc hiện tại (có thể thay đổi trước khi áp dụng)

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters; // Khởi tạo bộ lọc từ props hiện tại
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Nền trắng
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24), // Bo góc trên trái
          topRight: Radius.circular(24), // Bo góc trên phải (bottom sheet style)
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Chiều cao tự động theo nội dung
        children: [
          // Header - Phần đầu với gradient
          Container(
            padding: const EdgeInsets.all(20), // Padding 20px
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor, // Màu primary
                  Theme.of(context).primaryColor.withOpacity(0.8), // Màu primary nhạt hơn (gradient)
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24), // Bo góc trên
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Căn đều hai bên
              children: [
                const Text(
                  'Bộ lọc', // Tiêu đề
                  style: TextStyle(
                    fontSize: 20, // Kích thước chữ
                    fontWeight: FontWeight.bold, // Chữ đậm
                    color: Colors.white, // Màu trắng
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = FilterOptions(); // Reset bộ lọc về mặc định (xóa tất cả)
                    });
                  },
                  child: const Text(
                    'Xóa tất cả', // Nút xóa tất cả bộ lọc
                    style: TextStyle(color: Colors.white), // Màu trắng
                  ),
                ),
              ],
            ),
          ),

          // Filter content - Nội dung bộ lọc (có thể cuộn)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20), // Padding 20px
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
                children: [
                  _buildDateRangeSection(), // Phần chọn khoảng thời gian
                  const SizedBox(height: 24), // Khoảng cách giữa các section
                  _buildCategorySection(), // Phần chọn danh mục
                  const SizedBox(height: 24),
                  _buildWalletSection(), // Phần chọn ví
                  const SizedBox(height: 24),
                  _buildTagSection(), // Phần chọn tag
                  const SizedBox(height: 24),
                  _buildTransactionTypeSection(), // Phần chọn loại giao dịch
                ],
              ),
            ),
          ),

          // Apply button - Nút áp dụng bộ lọc
          Container(
            padding: const EdgeInsets.all(20), // Padding 20px
            decoration: BoxDecoration(
              color: Colors.white, // Nền trắng
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05), // Shadow nhẹ
                  blurRadius: 10, // Độ mờ
                  offset: const Offset(0, -5), // Shadow lên trên 5px (để tạo hiệu ứng nổi)
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity, // Chiều rộng full
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_filters); // Gọi callback với bộ lọc hiện tại
                  Navigator.pop(context); // Đóng bottom sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor, // Màu nền primary
                  padding: const EdgeInsets.symmetric(vertical: 16), // Padding dọc 16px
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Bo góc 12px
                  ),
                ),
                child: const Text(
                  'Áp dụng', // Text nút
                  style: TextStyle(
                    fontSize: 16, // Kích thước chữ
                    fontWeight: FontWeight.bold, // Chữ đậm
                    color: Colors.white, // Màu trắng
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng phần chọn khoảng thời gian với date picker và các nút nhanh
  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khoảng thời gian',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                context,
                _filters.startDate != null
                    ? DateFormat('dd/MM/yyyy').format(_filters.startDate!)
                    : 'Từ ngày',
                () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filters.startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _filters = _filters.copyWith(startDate: date);
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateButton(
                context,
                _filters.endDate != null
                    ? DateFormat('dd/MM/yyyy').format(_filters.endDate!)
                    : 'Đến ngày',
                () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filters.endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _filters = _filters.copyWith(endDate: date);
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateButton('7 ngày', 7),
            _buildQuickDateButton('30 ngày', 30),
            _buildQuickDateButton('90 ngày', 90),
          ],
        ),
      ],
    );
  }

  /// Xây dựng nút chọn ngày với date picker
  Widget _buildDateButton(
    BuildContext context,
    String label, // Nhãn hiển thị trên nút (ví dụ: "Từ ngày", "Đến ngày")
    VoidCallback onTap, // Callback khi nút được nhấn
  ) {
    return GestureDetector(
      onTap: onTap, // Xử lý sự kiện tap
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Padding dọc 12px, ngang 16px
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!), // Viền màu xám nhạt
          borderRadius: BorderRadius.circular(12), // Bo góc 12px
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]), // Icon lịch
            const SizedBox(width: 8), // Khoảng cách giữa icon và text
            Expanded(
              child: Text(
                label, // Hiển thị label (ngày đã chọn hoặc placeholder)
                style: TextStyle(fontSize: 14, color: Colors.grey[800]), // Chữ màu xám đậm
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Xây dựng nút chọn nhanh khoảng thời gian (7 ngày, 30 ngày, 90 ngày)
  Widget _buildQuickDateButton(String label, int days) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _filters = _filters.copyWith(
            endDate: DateTime.now(), // Ngày kết thúc = hôm nay
            startDate: DateTime.now().subtract(Duration(days: days)), // Ngày bắt đầu = hôm nay trừ đi số ngày
          );
        });
      },
      child: Text(label), // Hiển thị label (ví dụ: "7 ngày")
    );
  }

  /// Xây dựng phần chọn danh mục với FilterChip để chọn nhiều danh mục
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
      children: [
        const Text(
          'Danh mục', // Tiêu đề section
          style: TextStyle(
            fontSize: 16, // Kích thước chữ
            fontWeight: FontWeight.bold, // Chữ đậm
            color: Colors.black87, // Màu đen nhạt
          ),
        ),
        const SizedBox(height: 12), // Khoảng cách dưới tiêu đề
        Wrap(
          spacing: 8, // Khoảng cách ngang giữa các chip
          runSpacing: 8, // Khoảng cách dọc giữa các hàng
          children: widget.categories.map((category) {
            final isSelected = _filters.categoryIds.contains(category.id); // Kiểm tra danh mục có được chọn không
            return FilterChip(
              label: Text(category.name), // Hiển thị tên danh mục
              selected: isSelected, // Trạng thái được chọn
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    // Thêm danh mục vào danh sách đã chọn
                    _filters = _filters.copyWith(
                      categoryIds: [..._filters.categoryIds, category.id], // Thêm id mới vào mảng
                    );
                  } else {
                    // Xóa danh mục khỏi danh sách đã chọn
                    _filters = _filters.copyWith(
                      categoryIds: _filters.categoryIds
                          .where((id) => id != category.id) // Lọc bỏ id của danh mục này
                          .toList(),
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Xây dựng phần chọn ví với FilterChip để chọn nhiều ví
  Widget _buildWalletSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
      children: [
        const Text(
          'Ví', // Tiêu đề section
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12), // Khoảng cách
        Wrap(
          spacing: 8, // Khoảng cách ngang
          runSpacing: 8, // Khoảng cách dọc
          children: widget.wallets.map((wallet) {
            final isSelected = _filters.walletIds.contains(wallet.id); // Kiểm tra ví có được chọn không
            return FilterChip(
              label: Text(wallet.name), // Tên ví
              selected: isSelected, // Trạng thái được chọn
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    // Thêm ví vào danh sách đã chọn
                    _filters = _filters.copyWith(
                      walletIds: [..._filters.walletIds, wallet.id], // Thêm id mới
                    );
                  } else {
                    // Xóa ví khỏi danh sách đã chọn
                    _filters = _filters.copyWith(
                      walletIds: _filters.walletIds
                          .where((id) => id != wallet.id) // Lọc bỏ id của ví này
                          .toList(),
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Xây dựng phần chọn tag với FilterChip để chọn nhiều tag
  /// Ẩn phần này nếu không có tag nào
  Widget _buildTagSection() {
    if (widget.availableTags.isEmpty) {
      return const SizedBox.shrink(); // Ẩn hoàn toàn nếu không có tag
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
      children: [
        const Text(
          'Tag', // Tiêu đề section
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12), // Khoảng cách
        Wrap(
          spacing: 8, // Khoảng cách ngang
          runSpacing: 8, // Khoảng cách dọc
          children: widget.availableTags.map((tag) {
            final isSelected = _filters.tags.contains(tag); // Kiểm tra tag có được chọn không
            return FilterChip(
              label: Text(tag), // Tên tag
              selected: isSelected, // Trạng thái được chọn
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    // Thêm tag vào danh sách đã chọn
                    _filters = _filters.copyWith(tags: [..._filters.tags, tag]); // Thêm tag mới
                  } else {
                    // Xóa tag khỏi danh sách đã chọn
                    _filters = _filters.copyWith(
                      tags: _filters.tags.where((t) => t != tag).toList(), // Lọc bỏ tag này
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Xây dựng phần chọn loại giao dịch (thu nhập hoặc chi tiêu)
  /// Chỉ có thể chọn một loại tại một thời điểm (radio button behavior)
  Widget _buildTransactionTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Căn trái
      children: [
        const Text(
          'Loại giao dịch', // Tiêu đề section
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12), // Khoảng cách
        Wrap(
          spacing: 8, // Khoảng cách ngang
          children: [
            FilterChip(
              label: const Text('Thu nhập'), // Nhãn chip
              selected: _filters.transactionType == 'income', // Được chọn nếu transactionType là 'income'
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    transactionType: selected ? 'income' : null, // Đặt 'income' nếu chọn, null nếu bỏ chọn
                    clearTransactionType: !selected, // Xóa loại nếu bỏ chọn
                  );
                });
              },
            ),
            FilterChip(
              label: const Text('Chi tiêu'), // Nhãn chip
              selected: _filters.transactionType == 'expense', // Được chọn nếu transactionType là 'expense'
              onSelected: (selected) {
                setState(() {
                  _filters = _filters.copyWith(
                    transactionType: selected ? 'expense' : null, // Đặt 'expense' nếu chọn, null nếu bỏ chọn
                    clearTransactionType: !selected, // Xóa loại nếu bỏ chọn
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

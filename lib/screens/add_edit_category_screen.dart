// Import thư viện Flutter Material Design để sử dụng các widget UI
import 'package:flutter/material.dart';
// Import model CategoryModel để định nghĩa cấu trúc dữ liệu danh mục
import '../models/category_model.dart';
// Import service để thực hiện các thao tác CRUD với Firestore
import '../services/transaction_service.dart';
// Import file theme chứa các hằng số về màu sắc, font chữ, khoảng cách
import '../theme.dart';

/// Màn hình thêm mới hoặc chỉnh sửa danh mục
/// Có thể hoạt động ở 2 chế độ:
/// - Chế độ tạo mới: category = null, type được truyền vào
/// - Chế độ chỉnh sửa: category != null
class AddEditCategoryScreen extends StatefulWidget {
  // Danh mục cần chỉnh sửa (null nếu đang tạo mới)
  final CategoryModel?
  category; // null = chế độ tạo mới, not null = chế độ chỉnh sửa
  // Loại danh mục: 'income' (thu nhập) hoặc 'expense' (chi tiêu)
  // Bắt buộc khi ở chế độ tạo mới
  final String? type; // 'income' hoặc 'expense' - bắt buộc cho chế độ tạo mới

  // Constructor của widget với các tham số tùy chọn
  const AddEditCategoryScreen({
    super.key, // Key để Flutter quản lý widget tree
    this.category, // Danh mục cần chỉnh sửa (tùy chọn)
    this.type, // Loại danh mục (tùy chọn)
  });

  // Tạo State object để quản lý trạng thái của widget
  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

/// State class quản lý trạng thái và logic của màn hình
class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  // Key để quản lý và validate form
  final _formKey = GlobalKey<FormState>();
  // Controller để quản lý nội dung của TextField tên danh mục
  final _nameController = TextEditingController();
  // Instance của TransactionService để thực hiện các thao tác với Firestore
  final TransactionService _transactionService = TransactionService();

  // Icon được chọn, mặc định là 'category'
  String _selectedIcon = 'category';
  // Loại danh mục được chọn, mặc định là 'expense' (chi tiêu)
  String _selectedType = 'expense';
  // Trạng thái loading khi đang lưu dữ liệu
  final bool _isLoading = false;

  // ✅ TỐI ƯU HÓA: Sử dụng static const để tăng hiệu suất
  // Danh sách các icon có sẵn, được khai báo là static const để:
  // - Chỉ tạo 1 lần duy nhất trong bộ nhớ
  // - Không bị tạo lại mỗi khi widget rebuild
  // - Tiết kiệm bộ nhớ và tăng hiệu suất
  static const List<Map<String, dynamic>> _availableIconsData = [
    {'name': 'restaurant'}, // Icon nhà hàng (ăn uống)
    {'name': 'directions_car'}, // Icon xe hơi (phương tiện)
    {'name': 'shopping_cart'}, // Icon giỏ hàng (mua sắm)
    {'name': 'attach_money'}, // Icon tiền (tài chính)
    {'name': 'card_giftcard'}, // Icon quà tặng
    {'name': 'home'}, // Icon nhà (nhà ở)
    {'name': 'local_gas_station'}, // Icon trạm xăng (nhiên liệu)
    {'name': 'fitness_center'}, // Icon gym (thể dục)
    {'name': 'school'}, // Icon trường học (giáo dục)
    {'name': 'medical_services'}, // Icon y tế (sức khỏe)
    {'name': 'movie'}, // Icon phim (giải trí)
    {'name': 'flight'}, // Icon máy bay (du lịch)
    {'name': 'work'}, // Icon công việc
    {'name': 'account_balance'}, // Icon ngân hàng
    {'name': 'trending_up'}, // Icon tăng trưởng (đầu tư)
    {'name': 'savings'}, // Icon tiết kiệm
    {'name': 'local_grocery_store'}, // Icon cửa hàng tạp hóa
    {'name': 'phone'}, // Icon điện thoại (viễn thông)
    {'name': 'wifi'}, // Icon wifi (internet)
    {'name': 'electric_bolt'}, // Icon điện (tiện ích)
    {'name': 'water_drop'}, // Icon nước (tiện ích)
    {'name': 'local_pharmacy'}, // Icon nhà thuốc
    {'name': 'sports_esports'}, // Icon game (giải trí)
    {'name': 'music_note'}, // Icon âm nhạc
    {'name': 'book'}, // Icon sách (giáo dục)
    {'name': 'pets'}, // Icon thú cưng
    {'name': 'child_care'}, // Icon chăm sóc trẻ em
    {'name': 'celebration'}, // Icon lễ hội
    {'name': 'beach_access'}, // Icon bãi biển (du lịch)
    {'name': 'category'}, // Icon danh mục mặc định
  ];

  /// Phương thức khởi tạo, được gọi 1 lần khi State được tạo
  @override
  void initState() {
    super.initState(); // Gọi phương thức initState của lớp cha

    // Kiểm tra nếu đang ở chế độ chỉnh sửa (category != null)
    if (widget.category != null) {
      // Chế độ chỉnh sửa - điền dữ liệu vào các trường
      _nameController.text = widget.category!.name; // Điền tên danh mục
      _selectedIcon = widget.category!.icon; // Chọn icon hiện tại
      _selectedType = widget.category!.type; // Chọn loại hiện tại
    } else if (widget.type != null) {
      // Chế độ tạo mới với loại đã được chỉ định
      _selectedType = widget.type!; // Đặt loại theo tham số truyền vào
    }
  }

  /// Phương thức dọn dẹp, được gọi khi State bị hủy
  @override
  void dispose() {
    // Giải phóng bộ nhớ của TextEditingController để tránh memory leak
    _nameController.dispose();
    super.dispose(); // Gọi phương thức dispose của lớp cha
  }

  /// Getter để kiểm tra xem đang ở chế độ chỉnh sửa hay tạo mới
  /// Trả về true nếu category != null (chế độ chỉnh sửa)
  bool get _isEditMode => widget.category != null;

  // ✅ TỐI ƯU HÓA: Optimistic UI - đóng màn hình ngay lập tức, lưu ở background
  /// Phương thức lưu danh mục
  /// Sử dụng kỹ thuật Optimistic UI:
  /// - Đóng màn hình ngay lập tức để UX mượt mà
  /// - Lưu dữ liệu vào Firestore ở background
  Future<void> _saveCategory() async {
    // Validate form, nếu không hợp lệ thì dừng lại
    if (!_formKey.currentState!.validate()) {
      return; // Thoát khỏi hàm nếu validation thất bại
    }

    // Tạo object CategoryModel từ dữ liệu người dùng nhập
    final category = CategoryModel(
      // Nếu đang chỉnh sửa thì giữ nguyên ID, nếu tạo mới thì để rỗng
      id: _isEditMode ? widget.category!.id : '',
      // Lấy tên từ TextField và loại bỏ khoảng trắng thừa
      name: _nameController.text.trim(),
      // Icon đã chọn
      icon: _selectedIcon,
      // Loại danh mục (income/expense)
      type: _selectedType,
    );

    // ✅ Đóng màn hình ngay lập tức (Optimistic UI)
    // Kiểm tra widget còn tồn tại trong widget tree
    if (mounted) {
      Navigator.pop(context); // Quay lại màn hình trước
    }

    // ✅ Lưu dữ liệu vào Firestore ở background
    try {
      // Kiểm tra chế độ để gọi phương thức phù hợp
      if (_isEditMode) {
        // Cập nhật danh mục đã tồn tại
        await _transactionService.updateCategory(category);
      } else {
        // Thêm danh mục mới
        await _transactionService.addCategory(category);
      }
    } catch (e) {
      // Nếu có lỗi xảy ra sau khi đóng màn hình, không thể hiển thị snackbar
      // Trong môi trường production, nên sử dụng global error handler
      debugPrint('Error saving category: $e'); // In lỗi ra console để debug
    }
  }

  /// Xác nhận xóa danh mục
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc muốn xóa danh mục "${widget.category!.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Xóa',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Đóng màn hình trước (Optimistic UI)
      if (mounted) Navigator.pop(context);

      try {
        await _transactionService.deleteCategory(widget.category!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa danh mục thành công'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa danh mục: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  /// Phương thức build để tạo giao diện
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Container chính với gradient background
      body: Container(
        // Trang trí với gradient màu chính của app
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        // SafeArea đảm bảo nội dung không bị che bởi notch, status bar
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              // RepaintBoundary giúp tối ưu performance bằng cách tách layer riêng
              RepaintBoundary(
                child: Padding(
                  // Padding xung quanh AppBar
                  padding: const EdgeInsets.all(AppTheme.spacing),
                  child: Row(
                    children: [
                      // Nút quay lại
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () =>
                            Navigator.pop(context), // Quay lại màn hình trước
                      ),
                      const SizedBox(width: 8), // Khoảng cách giữa icon và text
                      // Tiêu đề màn hình, thay đổi theo chế độ
                      Expanded(
                        child: Text(
                          _isEditMode
                              ? 'Chỉnh sửa danh mục'
                              : 'Tạo danh mục mới',
                          style: const TextStyle(
                            fontSize: 24, // Kích thước chữ lớn
                            fontWeight: FontWeight.bold, // Chữ đậm
                            color: Colors.white, // Màu trắng
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Nút xóa (chỉ hiện khi đang sửa)
                      if (_isEditMode)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                          ),
                          onPressed: _confirmDelete,
                          tooltip: 'Xóa danh mục',
                        ),
                    ],
                  ),
                ),
              ),

              // Nội dung form
              Expanded(
                child: Container(
                  // Container với góc bo tròn ở trên
                  decoration: const BoxDecoration(
                    color: AppColors.background, // Màu nền
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                      topRight: Radius.circular(AppTheme.borderRadiusLarge),
                    ),
                  ),
                  child: Form(
                    key: _formKey, // Gắn key để quản lý form
                    child: ListView(
                      // Padding xung quanh nội dung
                      padding: const EdgeInsets.all(AppTheme.spacing),
                      // ✅ TỐI ƯU HÓA: Tắt cache để render nhanh hơn lần đầu
                      cacheExtent: 0,
                      children: [
                        const SizedBox(
                          height: AppTheme.spacing,
                        ), // Khoảng cách đầu
                        // Trường chọn loại danh mục (chỉ hiển thị ở chế độ tạo mới)
                        if (!_isEditMode) ...[
                          // Dropdown để chọn loại danh mục
                          DropdownButtonFormField<String>(
                            initialValue: _selectedType, // Giá trị ban đầu
                            decoration: const InputDecoration(
                              labelText: 'Loại danh mục', // Nhãn
                              prefixIcon: Icon(
                                Icons.category, // Icon danh mục
                                color: AppColors.primary, // Màu chính
                              ),
                              filled: true, // Có nền
                              fillColor: Colors.white, // Màu nền trắng
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(AppTheme.borderRadius),
                                ),
                                borderSide: BorderSide.none, // Không có viền
                              ),
                            ),
                            // Danh sách các lựa chọn
                            items: const [
                              // Lựa chọn Chi tiêu
                              DropdownMenuItem(
                                value: 'expense',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_down,
                                      color: AppColors.expense,
                                    ), // Icon giảm
                                    SizedBox(width: 8),
                                    Text('Chi tiêu'),
                                  ],
                                ),
                              ),
                              // Lựa chọn Thu nhập
                              DropdownMenuItem(
                                value: 'income',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: AppColors.income,
                                    ), // Icon tăng
                                    SizedBox(width: 8),
                                    Text('Thu nhập'),
                                  ],
                                ),
                              ),
                            ],
                            // Callback khi người dùng chọn
                            onChanged: (val) {
                              if (val != null) {
                                setState(
                                  () => _selectedType = val,
                                ); // Cập nhật state
                              }
                            },
                          ),
                          const SizedBox(
                            height: AppTheme.spacingLarge,
                          ), // Khoảng cách
                        ],

                        // Trường nhập tên danh mục
                        TextFormField(
                          controller: _nameController, // Gắn controller
                          decoration: const InputDecoration(
                            labelText: 'Tên danh mục', // Nhãn
                            hintText: 'VD: Ăn uống, Lương, ...', // Gợi ý
                            prefixIcon: Icon(Icons.label), // Icon nhãn
                          ),
                          // Hàm validate để kiểm tra dữ liệu nhập
                          validator: (value) {
                            // Kiểm tra nếu rỗng hoặc chỉ có khoảng trắng
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên danh mục'; // Thông báo lỗi
                            }
                            return null; // Hợp lệ
                          },
                        ),

                        const SizedBox(
                          height: AppTheme.spacingLarge,
                        ), // Khoảng cách
                        // Tiêu đề phần chọn icon
                        Text(
                          'Chọn icon',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600, // Chữ đậm vừa
                          ),
                        ),
                        const SizedBox(
                          height: AppTheme.spacingSmall,
                        ), // Khoảng cách nhỏ
                        // ✅ TỐI ƯU HÓA: Sử dụng widget riêng để cô lập việc rebuild
                        // RepaintBoundary tách layer riêng để tối ưu performance
                        RepaintBoundary(
                          child: _IconGrid(
                            availableIcons:
                                _availableIconsData, // Danh sách icon
                            selectedIcon: _selectedIcon, // Icon đang chọn
                            selectedType: _selectedType, // Loại đang chọn
                            // Callback khi chọn icon
                            onIconSelected: (iconName) {
                              setState(() {
                                _selectedIcon =
                                    iconName; // Cập nhật icon đã chọn
                              });
                            },
                          ),
                        ),

                        const SizedBox(
                          height: AppTheme.spacingLarge * 2,
                        ), // Khoảng cách lớn
                        // Nút lưu
                        RepaintBoundary(
                          child: Container(
                            width: double.infinity, // Chiều rộng full
                            height: 56, // Chiều cao cố định
                            decoration: BoxDecoration(
                              gradient: AppColors
                                  .primaryGradient, // Gradient màu chính
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius, // Bo góc
                              ),
                              // Đổ bóng để tạo độ nổi
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(
                                    0.3,
                                  ), // Màu bóng
                                  blurRadius: 12, // Độ mờ
                                  offset: const Offset(0, 4), // Vị trí bóng
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent, // Trong suốt
                              child: InkWell(
                                // Vô hiệu hóa nút khi đang loading
                                onTap: _isLoading ? null : _saveCategory,
                                borderRadius: BorderRadius.circular(
                                  AppTheme
                                      .borderRadius, // Bo góc cho hiệu ứng ripple
                                ),
                                child: Center(
                                  // Hiển thị loading indicator hoặc text
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          // Vòng tròn loading
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2, // Độ dày
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white, // Màu trắng
                                                ),
                                          ),
                                        )
                                      : Text(
                                          // Text thay đổi theo chế độ
                                          _isEditMode
                                              ? 'Cập nhật'
                                              : 'Tạo danh mục',
                                          style: AppTextStyles.button.copyWith(
                                            color: Colors.white, // Màu trắng
                                            fontSize: 18, // Kích thước chữ
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ TỐI ƯU HÓA: Pre-compute icon map để tra cứu O(1) thay vì dùng switch
/// Widget hiển thị lưới các icon để người dùng chọn
/// Được tách riêng để tối ưu performance và tái sử dụng
class _IconGrid extends StatelessWidget {
  // Danh sách các icon có sẵn
  final List<Map<String, dynamic>> availableIcons;
  // Icon đang được chọn
  final String selectedIcon;
  // Loại danh mục đang được chọn (để hiển thị màu phù hợp)
  final String selectedType;
  // Callback khi người dùng chọn icon
  final ValueChanged<String> onIconSelected;

  // Constructor với các tham số bắt buộc
  const _IconGrid({
    required this.availableIcons,
    required this.selectedIcon,
    required this.selectedType,
    required this.onIconSelected,
  });

  // ✅ TỐI ƯU HÓA: Map icon được tính toán trước để tra cứu nhanh
  // Sử dụng Map thay vì switch-case để tăng hiệu suất
  // Độ phức tạp O(1) thay vì O(n)
  static final Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant, // Nhà hàng
    'directions_car': Icons.directions_car, // Xe hơi
    'shopping_cart': Icons.shopping_cart, // Giỏ hàng
    'attach_money': Icons.attach_money, // Tiền
    'card_giftcard': Icons.card_giftcard, // Quà tặng
    'home': Icons.home, // Nhà
    'local_gas_station': Icons.local_gas_station, // Trạm xăng
    'fitness_center': Icons.fitness_center, // Gym
    'school': Icons.school, // Trường học
    'medical_services': Icons.medical_services, // Y tế
    'movie': Icons.movie, // Phim
    'flight': Icons.flight, // Máy bay
    'work': Icons.work, // Công việc
    'account_balance': Icons.account_balance, // Ngân hàng
    'trending_up': Icons.trending_up, // Tăng trưởng
    'savings': Icons.savings, // Tiết kiệm
    'local_grocery_store': Icons.local_grocery_store, // Tạp hóa
    'phone': Icons.phone, // Điện thoại
    'wifi': Icons.wifi, // Wifi
    'electric_bolt': Icons.electric_bolt, // Điện
    'water_drop': Icons.water_drop, // Nước
    'local_pharmacy': Icons.local_pharmacy, // Nhà thuốc
    'sports_esports': Icons.sports_esports, // Game
    'music_note': Icons.music_note, // Âm nhạc
    'book': Icons.book, // Sách
    'pets': Icons.pets, // Thú cưng
    'child_care': Icons.child_care, // Chăm sóc trẻ
    'celebration': Icons.celebration, // Lễ hội
    'beach_access': Icons.beach_access, // Bãi biển
  };

  /// Phương thức lấy IconData từ tên icon
  /// Trả về Icons.category nếu không tìm thấy
  IconData _getIconData(String iconName) {
    return _iconMap[iconName] ??
        Icons.category; // Trả về icon mặc định nếu không tìm thấy
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary để tối ưu performance
    return RepaintBoundary(
      child: Container(
        // Padding xung quanh grid
        padding: const EdgeInsets.all(AppTheme.spacing),
        decoration: BoxDecoration(
          color: Colors.white, // Nền trắng
          borderRadius: BorderRadius.circular(
            AppTheme.borderRadius, // Bo góc
          ),
        ),
        // GridView để hiển thị lưới icon
        child: GridView.builder(
          shrinkWrap: true, // Chỉ chiếm không gian cần thiết
          physics: const NeverScrollableScrollPhysics(), // Không scroll riêng
          // Cấu hình lưới
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // 5 cột
            mainAxisSpacing: 12, // Khoảng cách dọc
            crossAxisSpacing: 12, // Khoảng cách ngang
          ),
          itemCount: availableIcons.length, // Số lượng icon
          // ✅ TỐI ƯU HÓA: Tắt cache để render nhanh hơn lần đầu
          cacheExtent: 0,
          // Builder để tạo từng item
          itemBuilder: (context, index) {
            // Lấy dữ liệu icon tại vị trí index
            final iconData = availableIcons[index];
            // Lấy tên icon
            final iconName = iconData['name'] as String;
            // Lấy IconData từ tên
            final icon = _getIconData(iconName);
            // Kiểm tra xem icon này có đang được chọn không
            final isSelected = selectedIcon == iconName;

            // ✅ TỐI ƯU HÓA: Tính toán trước gradient và màu sắc
            // Gradient phụ thuộc vào loại danh mục và trạng thái chọn
            final gradient = isSelected
                ? (selectedType == 'income'
                      ? AppColors
                            .incomeGradient // Gradient xanh cho thu nhập
                      : AppColors.expenseGradient) // Gradient đỏ cho chi tiêu
                : null; // Không có gradient nếu không được chọn

            // Màu viền
            final borderColor = isSelected
                ? (selectedType == 'income'
                      ? AppColors
                            .income // Xanh cho thu nhập
                      : AppColors.expense) // Đỏ cho chi tiêu
                : Colors.transparent; // Trong suốt nếu không được chọn

            // Màu icon
            final iconColor = isSelected
                ? Colors
                      .white // Trắng nếu được chọn
                : Colors.grey.shade600; // Xám nếu không được chọn

            // RepaintBoundary cho từng item để tối ưu
            return RepaintBoundary(
              child: GestureDetector(
                // Callback khi tap vào icon
                onTap: () => onIconSelected(iconName),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient, // Gradient nếu được chọn
                    color: isSelected
                        ? null
                        : Colors.grey.shade100, // Nền xám nhạt nếu không chọn
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall, // Bo góc nhỏ
                    ),
                    border: Border.all(
                      color: borderColor, // Màu viền
                      width: 2, // Độ dày viền
                    ),
                  ),
                  child: Center(
                    // Hiển thị icon
                    child: Icon(
                      icon, // IconData
                      color: iconColor, // Màu icon
                      size: 24, // Kích thước icon
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

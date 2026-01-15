// Import thư viện Flutter Material Design để sử dụng các widget UI
import 'package:flutter/material.dart';
// Import thư viện services để định dạng input (chỉ cho phép nhập số)
import 'package:flutter/services.dart';
// Import thư viện intl để định dạng ngày tháng
import 'package:intl/intl.dart';
// Import Firebase Authentication để lấy thông tin user hiện tại
import 'package:firebase_auth/firebase_auth.dart';
// Import model BudgetModel để định nghĩa cấu trúc dữ liệu ngân sách
import '../models/budget_model.dart';
// Import model CategoryModel để định nghĩa cấu trúc dữ liệu danh mục
import '../models/category_model.dart';
// Import service để thực hiện các thao tác CRUD với ngân sách trên Firestore
import '../services/budget_service.dart';
// Import service để lấy danh sách danh mục từ Firestore
import '../services/transaction_service.dart';
// Import file theme chứa các hằng số về màu sắc, font chữ, khoảng cách
import '../theme.dart';
// Import widget button tùy chỉnh với gradient
import '../widgets/gradient_button.dart';
// Import widget text field tùy chỉnh
import '../widgets/custom_text_field.dart';

/// Màn hình thêm mới hoặc chỉnh sửa ngân sách
/// Có thể hoạt động ở 2 chế độ:
/// - Chế độ tạo mới: budget = null
/// - Chế độ chỉnh sửa: budget != null
class AddEditBudgetScreen extends StatefulWidget {
  // Ngân sách cần chỉnh sửa (null nếu đang tạo mới)
  final BudgetModel?
  budget; // null = chế độ thêm mới, not null = chế độ chỉnh sửa

  // Constructor của widget với tham số tùy chọn
  const AddEditBudgetScreen({super.key, this.budget});

  // Tạo State object để quản lý trạng thái của widget
  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

/// State class quản lý trạng thái và logic của màn hình
class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  // Key để quản lý và validate form
  final _formKey = GlobalKey<FormState>();
  // Instance của BudgetService để thực hiện các thao tác CRUD với Firestore
  final BudgetService _budgetService = BudgetService();
  // Instance của TransactionService để lấy danh sách danh mục
  final TransactionService _transactionService = TransactionService();

  // Controller để quản lý nội dung của TextField tên ngân sách
  // Sử dụng late vì sẽ được khởi tạo trong initState
  late TextEditingController _nameController;
  // Controller để quản lý nội dung của TextField số tiền
  late TextEditingController _amountController;

  // Chu kỳ ngân sách được chọn: 'monthly' (theo tháng), 'weekly' (theo tuần), 'custom' (tùy chỉnh)
  String _selectedPeriod = 'monthly';
  // ID của danh mục được chọn (null = áp dụng cho tất cả danh mục)
  String? _selectedCategoryId;
  // Ngày bắt đầu của ngân sách
  DateTime? _startDate;
  // Ngày kết thúc của ngân sách
  DateTime? _endDate;
  // Có tự động gia hạn ngân sách cho chu kỳ tiếp theo không
  bool _isRecurring = true;
  // Trạng thái loading khi đang lưu dữ liệu
  final bool _isLoading = false;

  /// Phương thức khởi tạo, được gọi 1 lần khi State được tạo
  @override
  void initState() {
    super.initState(); // Gọi phương thức initState của lớp cha

    // Khởi tạo các controller
    // Nếu đang chỉnh sửa thì điền tên hiện tại, không thì để rỗng
    _nameController = TextEditingController(text: widget.budget?.name ?? '');
    // Nếu đang chỉnh sửa thì điền số tiền hiện tại (không có số thập phân), không thì để rỗng
    _amountController = TextEditingController(
      text: widget.budget?.amount.toStringAsFixed(0) ?? '',
    );

    // Nếu đang ở chế độ chỉnh sửa, điền dữ liệu vào các trường
    if (widget.budget != null) {
      _selectedPeriod = widget.budget!.period; // Chu kỳ hiện tại
      _selectedCategoryId = widget.budget!.categoryId; // Danh mục hiện tại
      _startDate = widget.budget!.startDate; // Ngày bắt đầu hiện tại
      _endDate = widget.budget!.endDate; // Ngày kết thúc hiện tại
      _isRecurring = widget.budget!.isRecurring; // Trạng thái tự động gia hạn
    } else {
      // Nếu đang tạo mới, tính toán ngày mặc định dựa trên chu kỳ
      final dates = BudgetService.getPeriodDates(_selectedPeriod);
      _startDate = dates['startDate']; // Ngày bắt đầu mặc định
      _endDate = dates['endDate']; // Ngày kết thúc mặc định
    }
  }

  /// Phương thức dọn dẹp, được gọi khi State bị hủy
  @override
  void dispose() {
    // Giải phóng bộ nhớ của các TextEditingController để tránh memory leak
    _nameController.dispose();
    _amountController.dispose();
    super.dispose(); // Gọi phương thức dispose của lớp cha
  }

  /// Callback khi người dùng thay đổi chu kỳ ngân sách
  void _onPeriodChanged(String? period) {
    // Nếu giá trị null thì không làm gì
    if (period == null) return;

    // Cập nhật state
    setState(() {
      _selectedPeriod = period; // Cập nhật chu kỳ được chọn

      // Tự động cập nhật ngày bắt đầu và kết thúc khi chu kỳ thay đổi
      final dates = BudgetService.getPeriodDates(period);
      _startDate = dates['startDate']; // Ngày bắt đầu mới
      _endDate = dates['endDate']; // Ngày kết thúc mới

      // Tự động gia hạn chỉ có ý nghĩa với chu kỳ theo tháng/tuần
      // Nếu chọn tùy chỉnh thì tắt tự động gia hạn
      if (period == 'custom') {
        _isRecurring = false;
      }
    });
  }

  /// Phương thức hiển thị date picker để chọn ngày
  /// isStartDate: true = chọn ngày bắt đầu, false = chọn ngày kết thúc
  Future<void> _pickDate(bool isStartDate) async {
    // Hiển thị dialog chọn ngày
    final picked = await showDatePicker(
      context: context,
      // Ngày được chọn ban đầu trong picker
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now()) // Ngày bắt đầu hiện tại hoặc hôm nay
          : (_endDate ?? DateTime.now()), // Ngày kết thúc hiện tại hoặc hôm nay
      firstDate: DateTime(2020), // Ngày sớm nhất có thể chọn
      lastDate: DateTime(2030), // Ngày muộn nhất có thể chọn
      // Tùy chỉnh theme của date picker
      builder: (context, child) {
        return Theme(
          // Sao chép theme hiện tại và thay đổi màu chính
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!, // Widget date picker
        );
      },
    );

    // Nếu người dùng đã chọn ngày (không cancel)
    if (picked != null) {
      setState(() {
        // Cập nhật ngày tương ứng
        if (isStartDate) {
          _startDate = picked; // Cập nhật ngày bắt đầu
        } else {
          _endDate = picked; // Cập nhật ngày kết thúc
        }
      });
    }
  }

  /// Phương thức lưu ngân sách
  /// Sử dụng kỹ thuật Optimistic UI để UX mượt mà
  Future<void> _save() async {
    // Validate form, nếu không hợp lệ thì dừng lại
    if (!_formKey.currentState!.validate()) return;

    // ✅ Optimistic UI: Chuẩn bị dữ liệu
    // Lấy ID của user hiện tại từ Firebase Auth
    final userId = FirebaseAuth.instance.currentUser!.uid;
    // Parse số tiền từ string sang double (loại bỏ dấu phẩy nếu có)
    final amount = double.parse(_amountController.text.replaceAll(',', ''));

    // Tạo object BudgetModel từ dữ liệu người dùng nhập
    final budget = BudgetModel(
      // Nếu đang chỉnh sửa thì giữ nguyên ID, nếu tạo mới thì để rỗng
      id: widget.budget?.id ?? '',
      userId: userId, // ID của user
      name: _nameController.text
          .trim(), // Tên ngân sách (loại bỏ khoảng trắng thừa)
      amount: amount, // Số tiền giới hạn
      period: _selectedPeriod, // Chu kỳ (monthly/weekly/custom)
      categoryId: _selectedCategoryId, // ID danh mục (null = tất cả)
      startDate: _startDate!, // Ngày bắt đầu
      endDate: _endDate!, // Ngày kết thúc
      isRecurring: _isRecurring, // Có tự động gia hạn không
      // Nếu đang chỉnh sửa thì giữ nguyên ngày tạo, nếu tạo mới thì dùng thời gian hiện tại
      createdAt: widget.budget?.createdAt ?? DateTime.now(),
    );

    // ✅ Optimistic UI: Đóng màn hình ngay lập tức
    // Kiểm tra widget còn tồn tại trong widget tree
    if (mounted) Navigator.pop(context); // Quay lại màn hình trước

    // Hiển thị thông báo đang xử lý
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          // Thông báo khác nhau tùy theo chế độ
          widget.budget == null
              ? 'Đang tạo ngân sách...'
              : 'Đang cập nhật ngân sách...',
        ),
        duration: const Duration(milliseconds: 1000), // Hiển thị trong 1 giây
      ),
    );

    // Chạy ở background (không block UI)
    try {
      // Kiểm tra chế độ để gọi phương thức phù hợp
      if (widget.budget == null) {
        // Thêm ngân sách mới vào Firestore
        await _budgetService.addBudget(budget);
      } else {
        // Cập nhật ngân sách đã tồn tại trên Firestore
        await _budgetService.updateBudget(budget);
      }
    } catch (e) {
      // Nếu có lỗi, in ra console để debug
      debugPrint('Error saving budget: $e');
    }
  }

  /// Phương thức build để tạo giao diện
  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem đang ở chế độ chỉnh sửa hay tạo mới
    final isEditMode = widget.budget != null;

    return Scaffold(
      // Cho phép body mở rộng phía sau AppBar
      extendBodyBehindAppBar: true,
      // AppBar với gradient background
      appBar: AppBar(
        // Container với gradient làm background cho AppBar
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        // Tiêu đề thay đổi theo chế độ
        title: Text(isEditMode ? 'Sửa Ngân Sách' : 'Tạo Ngân Sách'),
      ),
      // Body chứa form
      body: Form(
        key: _formKey, // Gắn key để quản lý form
        child: ListView(
          // Padding xung quanh nội dung
          padding: const EdgeInsets.all(16),
          children: [
            // Khoảng cách để tránh bị che bởi AppBar
            const SizedBox(height: 100),

            // Trường nhập tên ngân sách
            CustomTextField(
              controller: _nameController, // Gắn controller
              label: 'Tên ngân sách', // Nhãn
              hint: 'VD: Ngân sách tháng 12', // Gợi ý
              prefixIcon: Icons.label, // Icon nhãn
              // Hàm validate để kiểm tra dữ liệu nhập
              validator: (value) {
                // Kiểm tra nếu rỗng
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên ngân sách'; // Thông báo lỗi
                }
                return null; // Hợp lệ
              },
            ),

            const SizedBox(height: 16), // Khoảng cách
            // Trường nhập số tiền giới hạn
            CustomTextField(
              controller: _amountController, // Gắn controller
              label: 'Số tiền giới hạn (₫)', // Nhãn với ký hiệu tiền tệ
              hint: '0', // Gợi ý
              prefixIcon: Icons.attach_money, // Icon tiền
              keyboardType: TextInputType.number, // Bàn phím số
              // Chỉ cho phép nhập số
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              // Hàm validate để kiểm tra dữ liệu nhập
              validator: (value) {
                // Kiểm tra nếu rỗng
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số tiền'; // Thông báo lỗi
                }
                // Parse sang số và kiểm tra tính hợp lệ
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Số tiền phải lớn hơn 0'; // Thông báo lỗi
                }
                return null; // Hợp lệ
              },
            ),

            const SizedBox(height: 16), // Khoảng cách
            // Dropdown chọn chu kỳ ngân sách
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriod, // Giá trị ban đầu
              decoration: const InputDecoration(
                labelText: 'Chu kỳ', // Nhãn
                prefixIcon: Icon(Icons.calendar_today), // Icon lịch
              ),
              // Danh sách các lựa chọn
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Theo tháng')),
                DropdownMenuItem(value: 'weekly', child: Text('Theo tuần')),
                DropdownMenuItem(value: 'custom', child: Text('Tùy chỉnh')),
              ],
              // Callback khi người dùng chọn
              onChanged: _onPeriodChanged,
            ),

            const SizedBox(height: 16), // Khoảng cách
            // Trường chọn ngày (chỉ hiển thị khi chu kỳ là tùy chỉnh)
            if (_selectedPeriod == 'custom') ...[
              // Row chứa 2 trường chọn ngày bắt đầu và kết thúc
              Row(
                children: [
                  // Trường chọn ngày bắt đầu
                  Expanded(
                    child: GestureDetector(
                      // Khi tap vào thì hiển thị date picker
                      onTap: () => _pickDate(true),
                      child: AbsorbPointer(
                        // AbsorbPointer ngăn TextField nhận input trực tiếp
                        child: CustomTextField(
                          // Controller tạm thời để hiển thị ngày đã chọn
                          controller: TextEditingController(
                            text: _startDate != null
                                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                                : '',
                          ),
                          label: 'Ngày bắt đầu', // Nhãn
                          prefixIcon: Icons.calendar_today, // Icon lịch
                          // Hàm validate
                          validator: (value) {
                            if (_startDate == null) {
                              return 'Chọn ngày bắt đầu'; // Thông báo lỗi
                            }
                            return null; // Hợp lệ
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Khoảng cách giữa 2 trường
                  // Trường chọn ngày kết thúc
                  Expanded(
                    child: GestureDetector(
                      // Khi tap vào thì hiển thị date picker
                      onTap: () => _pickDate(false),
                      child: AbsorbPointer(
                        // AbsorbPointer ngăn TextField nhận input trực tiếp
                        child: CustomTextField(
                          // Controller tạm thời để hiển thị ngày đã chọn
                          controller: TextEditingController(
                            text: _endDate != null
                                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                : '',
                          ),
                          label: 'Ngày kết thúc', // Nhãn
                          prefixIcon: Icons.calendar_today, // Icon lịch
                          // Hàm validate
                          validator: (value) {
                            if (_endDate == null) {
                              return 'Chọn ngày kết thúc'; // Thông báo lỗi
                            }
                            // Kiểm tra ngày kết thúc phải sau ngày bắt đầu
                            if (_startDate != null &&
                                _endDate!.isBefore(_startDate!)) {
                              return 'Ngày kết thúc phải sau ngày bắt đầu';
                            }
                            return null; // Hợp lệ
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Khoảng cách
            ] else ...[
              // Hiển thị ngày được tính tự động (khi không phải chu kỳ tùy chỉnh)
              Container(
                padding: const EdgeInsets.all(16), // Padding bên trong
                decoration: BoxDecoration(
                  // Màu nền xanh nhạt
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12), // Bo góc
                ),
                child: Row(
                  children: [
                    // Icon thông tin
                    const Icon(Icons.info, color: AppColors.primary),
                    const SizedBox(width: 12), // Khoảng cách
                    // Text hiển thị khoảng thời gian
                    Expanded(
                      child: Text(
                        'Từ ${DateFormat('dd/MM/yyyy').format(_startDate!)} đến ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16), // Khoảng cách
            ],

            // Dropdown chọn danh mục
            // Sử dụng StreamBuilder để lắng nghe thay đổi từ Firestore
            StreamBuilder<List<CategoryModel>>(
              // Stream lấy danh sách danh mục từ Firestore
              stream: _transactionService.getCategories(),
              builder: (context, snapshot) {
                // Lấy danh sách danh mục từ snapshot (hoặc list rỗng nếu chưa có dữ liệu)
                final categories = snapshot.data ?? [];
                // Lọc chỉ lấy danh mục chi tiêu (vì ngân sách chỉ áp dụng cho chi tiêu)
                final expenseCategories = categories
                    .where((c) => c.type == 'expense')
                    .toList();

                // Dropdown để chọn danh mục
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId, // Giá trị ban đầu
                  decoration: const InputDecoration(
                    labelText: 'Danh mục', // Nhãn
                    prefixIcon: Icon(Icons.category), // Icon danh mục
                  ),
                  items: [
                    // Lựa chọn "Tất cả danh mục" với giá trị null
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả danh mục'),
                    ),
                    // Map các danh mục chi tiêu thành DropdownMenuItem
                    ...expenseCategories.map((category) {
                      return DropdownMenuItem(
                        value: category.id, // Giá trị là ID danh mục
                        child: Text(category.name), // Hiển thị tên danh mục
                      );
                    }),
                  ],
                  // Callback khi người dùng chọn
                  onChanged: (value) {
                    setState(
                      () => _selectedCategoryId = value,
                    ); // Cập nhật state
                  },
                );
              },
            ),

            const SizedBox(height: 16), // Khoảng cách
            // Switch tự động gia hạn (chỉ hiển thị khi không phải chu kỳ tùy chỉnh)
            if (_selectedPeriod != 'custom')
              SwitchListTile(
                title: const Text('Tự động gia hạn'), // Tiêu đề
                subtitle: const Text(
                  'Tự động tạo ngân sách mới cho chu kỳ tiếp theo', // Mô tả
                ),
                value: _isRecurring, // Giá trị hiện tại
                // Callback khi người dùng toggle switch
                onChanged: (value) {
                  setState(() => _isRecurring = value); // Cập nhật state
                },
                activeThumbColor: AppColors.primary, // Màu khi bật
              ),

            const SizedBox(height: 32), // Khoảng cách lớn
            // Nút lưu với gradient
            GradientButton(
              // Vô hiệu hóa nút khi đang loading
              onPressed: _isLoading ? null : _save,
              gradient: AppColors.primaryGradient, // Gradient màu chính
              // Hiển thị loading indicator hoặc text
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      // Vòng tròn loading
                      child: CircularProgressIndicator(
                        color: Colors.white, // Màu trắng
                        strokeWidth: 2, // Độ dày
                      ),
                    )
                  : Text(
                      // Text thay đổi theo chế độ
                      isEditMode ? 'Cập nhật' : 'Tạo ngân sách',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
            ),

            // Khoảng cách cuối để tránh bị che bởi bottom navigation
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

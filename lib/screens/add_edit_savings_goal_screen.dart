import 'package:flutter/material.dart'; // UI framework Flutter
import 'package:flutter/services.dart'; // InputFormatters (lọc ký tự nhập)
import 'package:intl/intl.dart'; // Định dạng ngày/tháng (DateFormat)
import 'package:firebase_auth/firebase_auth.dart'; // Lấy user hiện tại (uid)
import '../models/savings_goal_model.dart'; // Model dữ liệu Mục tiêu tiết kiệm
import '../services/savings_goal_service.dart'; // Service thao tác DB (add/update)
import '../theme.dart'; // Màu sắc + text style chung của app
import '../widgets/gradient_button.dart'; // Nút có gradient custom
import '../widgets/custom_text_field.dart'; // TextField custom của app

/// Màn hình dùng chung cho:
/// - Add mode: widget.goal == null
/// - Edit mode: widget.goal != null
class AddEditSavingsGoalScreen extends StatefulWidget {
  final SavingsGoalModel? goal; // null = tạo mới, != null = chỉnh sửa

  const AddEditSavingsGoalScreen({super.key, this.goal});

  @override
  State<AddEditSavingsGoalScreen> createState() =>
      _AddEditSavingsGoalScreenState();
}

class _AddEditSavingsGoalScreenState extends State<AddEditSavingsGoalScreen> {
  /// Key để validate Form (gọi _formKey.currentState!.validate())
  final _formKey = GlobalKey<FormState>();

  /// Service thao tác dữ liệu mục tiêu (Firestore/Database)
  final SavingsGoalService _goalService = SavingsGoalService();

  /// Controller để lấy text từ các ô nhập
  late TextEditingController _nameController; // tên mục tiêu
  late TextEditingController _targetAmountController; // số tiền mục tiêu
  late TextEditingController _descriptionController; // mô tả

  /// Các state người dùng chọn trong form
  DateTime? _deadline; // hạn chót (bắt buộc)
  String _selectedIcon = 'savings'; // icon đang chọn (mặc định)
  String _selectedColor = 'FF6B4EFF'; // màu đang chọn (mặc định tím)

  /// Trạng thái loading để disable nút Save (hiện đang để final false)
  /// Lưu ý: nếu muốn bật/tắt loading thật, phải bỏ "final" và setState khi save.
  final bool _isLoading = false;

  /// Danh sách icon có sẵn để chọn
  /// - name: giá trị lưu vào DB
  /// - icon: IconData để hiển thị
  /// - label: tên hiển thị cho người dùng
  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'savings', 'icon': Icons.savings, 'label': 'Tiết kiệm'},
    {'name': 'car', 'icon': Icons.directions_car, 'label': 'Xe hơi'},
    {'name': 'flight', 'icon': Icons.flight, 'label': 'Du lịch'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Nhà'},
    {'name': 'school', 'icon': Icons.school, 'label': 'Học tập'},
    {'name': 'shopping', 'icon': Icons.shopping_bag, 'label': 'Mua sắm'},
    {'name': 'phone', 'icon': Icons.phone_android, 'label': 'Điện thoại'},
    {'name': 'computer', 'icon': Icons.computer, 'label': 'Máy tính'},
    {'name': 'camera', 'icon': Icons.camera_alt, 'label': 'Máy ảnh'},
    {'name': 'gift', 'icon': Icons.card_giftcard, 'label': 'Quà tặng'},
    {'name': 'heart', 'icon': Icons.favorite, 'label': 'Yêu thích'},
    {'name': 'star', 'icon': Icons.star, 'label': 'Đặc biệt'},
    {'name': 'wallet', 'icon': Icons.account_balance_wallet, 'label': 'Ví'},
    {'name': 'beach', 'icon': Icons.beach_access, 'label': 'Biển'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Nhà hàng'},
    {'name': 'fitness', 'icon': Icons.fitness_center, 'label': 'Thể hình'},
  ];

  /// Danh sách màu có sẵn (value là ARGB hex string)
  final List<Map<String, dynamic>> _availableColors = [
    {'name': 'Purple', 'value': 'FF6B4EFF'},
    {'name': 'Blue', 'value': 'FF2196F3'},
    {'name': 'Teal', 'value': 'FF009688'},
    {'name': 'Green', 'value': 'FF4CAF50'},
    {'name': 'Orange', 'value': 'FFFF9800'},
    {'name': 'Red', 'value': 'FFF44336'},
    {'name': 'Pink', 'value': 'FFE91E63'},
    {'name': 'Indigo', 'value': 'FF3F51B5'},
  ];

  @override
  void initState() {
    super.initState();

    /// Khởi tạo controller.
    /// - Nếu edit mode => lấy dữ liệu từ widget.goal
    /// - Nếu add mode => rỗng
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetAmountController = TextEditingController(
      // Nếu edit: hiển thị số tiền (làm tròn 0 chữ số thập phân)
      text: widget.goal?.targetAmount.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.goal?.description ?? '',
    );

    /// Nếu edit mode => fill các state chọn sẵn
    if (widget.goal != null) {
      _deadline = widget.goal!.deadline;
      _selectedIcon = widget.goal!.iconName;
      _selectedColor = widget.goal!.color;
    }
  }

  @override
  void dispose() {
    /// Giải phóng controller để tránh memory leak
    _nameController.dispose();
    _targetAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Mở DatePicker để chọn hạn chót
  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      // Nếu đã chọn rồi thì dùng lại, chưa chọn thì mặc định +30 ngày
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      // Không cho chọn ngày trong quá khứ
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      // Tùy biến theme của date picker (màu primary)
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    // Nếu user chọn ngày => lưu vào state
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  /// BottomSheet cho người dùng chọn icon mục tiêu
  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chọn biểu tượng', style: AppTextStyles.h3),
              const SizedBox(height: 20),

              /// Expanded để GridView có thể cuộn trong bottom sheet
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final item = _availableIcons[index];
                    final isSelected = _selectedIcon == item['name'];

                    return GestureDetector(
                      // Khi chọn icon: cập nhật state + đóng bottom sheet
                      onTap: () {
                        setState(() {
                          _selectedIcon = item['name'];
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          // Nếu selected => highlight nền + viền primary
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.2)
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'],
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['label'],
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// BottomSheet cho người dùng chọn màu
  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Chọn màu sắc', style: AppTextStyles.h3),
              const SizedBox(height: 20),

              /// Wrap để hiển thị danh sách màu dạng các vòng tròn
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _availableColors.map((colorData) {
                  // Chuyển hex string -> Color
                  final color = Color(int.parse('0x${colorData['value']}'));
                  final isSelected = _selectedColor == colorData['value'];

                  return GestureDetector(
                    // Khi chọn màu: cập nhật state + đóng bottom sheet
                    onTap: () {
                      setState(() {
                        _selectedColor = colorData['value'];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        // Nếu selected => viền trắng
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        // Đổ bóng nhẹ cùng tông màu
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      // Nếu selected => hiện dấu check
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  /// Validate + tạo SavingsGoalModel + gọi service để add/update
  Future<void> _save() async {
    // 1) Validate các TextField trong Form
    if (!_formKey.currentState!.validate()) return;

    // 2) Check hạn chót (vì deadline không nhập trực tiếp)
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hạn chót')),
      );
      return;
    }

    // 3) Lấy userId hiện tại từ FirebaseAuth
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // 4) Parse số tiền mục tiêu (xóa dấu phẩy nếu có)
    final targetAmount = double.parse(
      _targetAmountController.text.replaceAll(',', ''),
    );

    // 5) Tạo object goal (dữ liệu sẽ lưu DB)
    final goal = SavingsGoalModel(
      id: widget.goal?.id ?? '', // nếu edit => giữ id, nếu add => để rỗng
      userId: userId,
      name: _nameController.text.trim(),
      targetAmount: targetAmount,
      currentAmount:
          widget.goal?.currentAmount ?? 0, // edit giữ currentAmount, add = 0
      deadline: _deadline!,
      iconName: _selectedIcon,
      color: _selectedColor,

      // description: nếu rỗng => null (đỡ lưu string rỗng)
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),

      // createdAt: edit giữ ngày tạo cũ, add thì now
      createdAt: widget.goal?.createdAt ?? DateTime.now(),
      // updatedAt: luôn cập nhật thời điểm hiện tại
      updatedAt: DateTime.now(),
    );

    // 6) Optimistic UI: đóng màn hình ngay để app cảm giác "nhanh"
    if (mounted) Navigator.pop(context);

    // 7) Hiện snackbar trạng thái đang xử lý
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.goal == null
              ? 'Đang tạo mục tiêu...'
              : 'Đang cập nhật mục tiêu...',
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );

    // 8) Thực hiện lưu dữ liệu thật (try/catch để tránh crash)
    try {
      if (widget.goal == null) {
        // Add mode
        await _goalService.addGoal(goal);
      } else {
        // Edit mode
        await _goalService.updateGoal(goal);
      }
    } catch (e) {
      // Nếu lỗi, hiện chỉ log ra console (có thể nâng cấp: show snackbar lỗi)
      debugPrint('Error saving savings goal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Xác định mode theo goal có null hay không
    final isEditMode = widget.goal != null;

    // Màu đang chọn (từ hex string sang Color)
    final selectedColor = Color(int.parse('0x$_selectedColor'));

    // Lấy IconData tương ứng với _selectedIcon để hiển thị preview
    final selectedIconData =
        _availableIcons.firstWhere((i) => i['name'] == _selectedIcon)['icon']
            as IconData;

    return Scaffold(
      // Cho phép body "đè" lên AppBar để tạo effect đẹp
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // Tô nền AppBar bằng gradient
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        // Title thay đổi theo mode
        title: Text(isEditMode ? 'Sửa Mục Tiêu' : 'Tạo Mục Tiêu'),
      ),

      // Form: bao toàn bộ UI input để validate
      body: Form(
        key: _formKey,
        child: ListView(
          // ListView để màn hình có thể cuộn khi bàn phím bật
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 100),

            /// Preview icon + màu đã chọn
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  // Gradient nhẹ theo màu đã chọn
                  gradient: LinearGradient(
                    colors: [
                      selectedColor.withOpacity(0.3),
                      selectedColor.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(selectedIconData, size: 64, color: selectedColor),
              ),
            ),

            const SizedBox(height: 20),

            /// 2 nút chọn icon và màu
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    onPressed: _showIconPicker, // mở bottom sheet icon
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cardBackground,
                        AppColors.cardBackground.withOpacity(0.8),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedIconData,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Biểu tượng',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    onPressed: _showColorPicker, // mở bottom sheet màu
                    gradient: LinearGradient(
                      colors: [selectedColor, selectedColor.withOpacity(0.8)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.palette, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Màu sắc',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// TextField nhập tên mục tiêu (bắt buộc)
            CustomTextField(
              controller: _nameController,
              label: 'Tên mục tiêu',
              hint: 'VD: Mua xe, Du lịch Nhật Bản',
              prefixIcon: Icons.flag,
              validator: (value) {
                // Validate: không được rỗng
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên mục tiêu';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            /// TextField nhập số tiền mục tiêu (bắt buộc)
            CustomTextField(
              controller: _targetAmountController,
              label: 'Số tiền mục tiêu (₫)',
              hint: '0',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
              // Chỉ cho nhập chữ số
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số tiền mục tiêu';
                }
                // Parse thử để đảm bảo hợp lệ
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            /// Deadline picker:
            /// - Dùng GestureDetector để bắt tap
            /// - Dùng AbsorbPointer để user không gõ tay vào ô
            GestureDetector(
              onTap: _pickDeadline,
              child: AbsorbPointer(
                child: CustomTextField(
                  // Tạo controller tạm để hiển thị ngày đã chọn
                  // (Lưu ý: tạo mới trong build là được, nhưng có thể tối ưu bằng controller riêng)
                  controller: TextEditingController(
                    text: _deadline != null
                        ? DateFormat('dd/MM/yyyy').format(_deadline!)
                        : '',
                  ),
                  label: 'Hạn chót',
                  hint: 'Chọn ngày',
                  prefixIcon: Icons.calendar_today,
                  validator: (value) {
                    // Validate dựa vào _deadline
                    if (_deadline == null) {
                      return 'Vui lòng chọn hạn chót';
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Mô tả (không bắt buộc)
            CustomTextField(
              controller: _descriptionController,
              label: 'Mô tả (không bắt buộc)',
              hint: 'Thêm ghi chú về mục tiêu của bạn',
              prefixIcon: Icons.description,
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            /// Nút lưu:
            /// - disable khi loading
            /// - gọi _save để validate và lưu
            GradientButton(
              onPressed: _isLoading ? null : _save,
              gradient: AppColors.primaryGradient,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEditMode ? 'Cập nhật' : 'Tạo mục tiêu',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart'; // UI Flutter
import 'package:intl/intl.dart'; // Format ngày/giờ và số tiền
import '../models/transaction_model.dart'; // Model giao dịch
import '../models/category_model.dart'; // Model danh mục
import '../models/wallet_model.dart'; // Model ví
import '../services/transaction_service.dart'; // Service CRUD giao dịch + stream categories/wallets
import '../services/auth_service.dart'; // Service auth (lấy currentUser)
import '../theme.dart'; // Theme chung: màu, spacing, text styles
import '../widgets/gradient_button.dart'; // Nút gradient custom
import '../widgets/custom_text_field.dart'; // TextField custom

/// Màn hình dùng chung cho:
/// - Thêm giao dịch (widget.transaction == null)
/// - Sửa giao dịch (widget.transaction != null)
class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction; // null = add mode, != null = edit mode

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  /// Controller đọc input từ các ô nhập
  final _amountController = TextEditingController(); // số tiền
  final _noteController = TextEditingController(); // ghi chú
  final _tagsController = TextEditingController(); // tags (dạng text "a, b, c")

  /// State người dùng chọn
  DateTime _selectedDate =
      DateTime.now(); // ngày giờ giao dịch (mặc định hiện tại)
  String _type = 'expense'; // loại giao dịch: 'expense' hoặc 'income'
  String? _selectedCategoryId; // id danh mục đã chọn
  String? _selectedWalletId; // id ví đã chọn

  /// Service thao tác dữ liệu
  final _transactionService = TransactionService();
  final _authService = AuthService();

  /// Cờ loading cho nút (hiện tại đang để final false nên sẽ KHÔNG đổi được)
  /// Nếu muốn loading thật: đổi thành "bool _isLoading = false;" và setState.
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    /// Nếu có transaction => edit mode => đổ dữ liệu cũ lên form
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _amountController.text = t.amount.toStringAsFixed(
        0,
      ); // số tiền không thập phân
      _noteController.text = t.note ?? ''; // note có thể null
      _tagsController.text = t.tags.join(', '); // list tags -> text "a, b"
      _selectedDate = t.date;
      _type = t.type; // expense/income
      _selectedCategoryId = t.categoryId;
      _selectedWalletId = t.walletId;
    }
  }

  @override
  void dispose() {
    /// Dispose controller tránh memory leak
    _amountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  /// Chọn ngày + giờ:
  /// - showDatePicker => lấy picked (ngày)
  /// - showTimePicker => lấy time (giờ)
  /// - gộp lại thành DateTime đầy đủ (year/month/day/hour/minute)
  // Chọn ngày và giờ riêng biệt, sau đó gộp lại
  Future<void> _pickDate() async {
    // 1. Chọn ngày (Date Picker)
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      // Custom theme cho picker
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    // 2. Nếu đã chọn ngày -> Chọn giờ (Time Picker)
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          );
        },
      );

      // 3. Gộp Ngày + Giờ thành DateTime hoàn chỉnh
      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  /// Lưu giao dịch:
  /// - Validate tối thiểu: amount + category + wallet
  /// - Check login
  /// - Parse amount, parse tags
  /// - Tạo TransactionModel mới
  /// - Optimistic UI: pop + snackbar
  /// - Gọi add/update ở background
  Future<void> _save() async {
    // Validate input tối thiểu (ở đây không dùng Form validator)
    if (_amountController.text.isEmpty ||
        _selectedCategoryId == null ||
        _selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền, chọn danh mục và ví'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Lấy user hiện tại
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đăng nhập'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Parse amount (xóa dấu phẩy nếu có)
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    // Parse tags: "a, b, c" -> ["a","b","c"] (loại bỏ rỗng)
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Tạo transaction mới (dùng chung cho add/update)
    final newTransaction = TransactionModel(
      id:
          widget.transaction?.id ??
          '', // edit giữ id, add để rỗng (service sẽ tạo id)
      userId: user.uid,
      amount: amount,
      type: _type,
      date: _selectedDate,
      note: _noteController.text.trim(), // note không bắt buộc
      categoryId: _selectedCategoryId!, // đã check null ở trên
      walletId: _selectedWalletId!, // đã check null ở trên
      tags: tags,
    );

    // ✅ Optimistic UI: Đóng màn hình ngay để tạo cảm giác nhanh mượt
    if (mounted) Navigator.of(context).pop();

    // Hiển thị thông báo (SnackBar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.transaction == null ? 'Đang thêm...' : 'Đang cập nhật...',
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );

    // Thực hiện lưu DB ở background (sau khi đã pop màn hình)
    try {
      if (widget.transaction == null) {
        // Add mode: thêm mới
        await _transactionService.addTransaction(newTransaction);
      } else {
        // Edit mode: cập nhật (cần transaction cũ để tính lại số dư ví nếu cần)
        await _transactionService.updateTransaction(
          widget.transaction!,
          newTransaction,
        );
      }
    } catch (e) {
      // Lưu ý: Vì màn hình đã đóng, nên chỉ có thể log lỗi
      debugPrint('Error saving transaction: $e');
    }
  }

  /// Xóa giao dịch (chỉ edit mode):
  /// - Hỏi confirm
  /// - Optimistic UI: pop + snackbar
  /// - Gọi delete ở background
  Future<void> _delete() async {
    if (widget.transaction == null) return;

    // Dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: const Text('Xóa giao dịch?'),
        content: const Text('Bạn có chắc muốn xóa giao dịch này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // ✅ Optimistic UI: đóng màn ngay
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang xóa...'),
          duration: Duration(milliseconds: 1000),
        ),
      );

      // Xóa thật ở background
      try {
        await _transactionService.deleteTransaction(widget.transaction!);
      } catch (e) {
        debugPrint('Error deleting transaction: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chọn gradient theo loại giao dịch để đổi “màu chủ đạo”
    final gradient = _type == 'expense'
        ? AppColors.expenseGradient
        : AppColors.incomeGradient;

    return Scaffold(
      // Cho body “đè” lên AppBar để tạo effect nền đẹp
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // AppBar nền gradient theo type
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
        title: Text(
          widget.transaction == null ? 'Thêm Giao Dịch' : 'Sửa Giao Dịch',
        ),
        actions: [
          // Chỉ hiện nút xóa khi edit mode
          if (widget.transaction != null)
            IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),

      // Background: gradient nhẹ phía trên + trắng phía dưới
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradient.colors.first.withOpacity(0.1), Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // ScrollView để không bị overflow khi bàn phím bật
            padding: const EdgeInsets.all(AppTheme.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================================================
                // TYPE SELECTOR (Chi tiêu / Thu nhập) có animation
                // =========================================================
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppTheme.animationDuration,
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    // Fade + slide lên nhẹ
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // =========================
                        // Expense tab
                        // =========================
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _type = 'expense'),
                            child: AnimatedContainer(
                              duration: AppTheme.animationDuration,
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                // Nếu đang expense => tô gradient expense
                                gradient: _type == 'expense'
                                    ? AppColors.expenseGradient
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadius,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Đổi icon mượt bằng AnimatedSwitcher
                                  AnimatedSwitcher(
                                    duration: AppTheme.animationDurationFast,
                                    child: Icon(
                                      Icons.arrow_downward,
                                      key: ValueKey(_type == 'expense'),
                                      color: _type == 'expense'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Đổi style text mượt
                                  AnimatedDefaultTextStyle(
                                    duration: AppTheme.animationDuration,
                                    curve: Curves.easeInOut,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: _type == 'expense'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: _type == 'expense'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    child: const Text('Chi tiêu'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // =========================
                        // Income tab
                        // =========================
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _type = 'income'),
                            child: AnimatedContainer(
                              duration: AppTheme.animationDuration,
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: _type == 'income'
                                    ? AppColors.incomeGradient
                                    : null,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadius,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: AppTheme.animationDurationFast,
                                    child: Icon(
                                      Icons.arrow_upward,
                                      key: ValueKey(_type == 'income'),
                                      color: _type == 'income'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedDefaultTextStyle(
                                    duration: AppTheme.animationDuration,
                                    curve: Curves.easeInOut,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      color: _type == 'income'
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: _type == 'income'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    child: const Text('Thu nhập'),
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
                const SizedBox(height: AppTheme.spacingLarge),

                // =========================================================
                // AMOUNT INPUT
                // =========================================================
                Text('Số tiền', style: AppTextStyles.h3),
                const SizedBox(height: AppTheme.spacingSmall),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  // Số tiền lớn, đổi màu theo type
                  style: AppTextStyles.amountLarge.copyWith(
                    color: _type == 'expense'
                        ? AppColors.expense
                        : AppColors.income,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTextStyles.amountLarge.copyWith(
                      color: AppColors.textHint,
                    ),
                    // Hiển thị hậu tố đơn vị "đ"
                    suffix: Text(
                      'đ',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    filled: true,
                    // Nền nhẹ theo type để “gợi cảm giác”
                    fillColor:
                        (_type == 'expense'
                                ? AppColors.expense
                                : AppColors.income)
                            .withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLarge),

                // =========================================================
                // CATEGORY DROPDOWN (lọc theo type)
                // =========================================================
                Text('Danh mục', style: AppTextStyles.h3),
                const SizedBox(height: AppTheme.spacingSmall),
                StreamBuilder<List<CategoryModel>>(
                  // Stream danh mục (service cung cấp)
                  stream: _transactionService.getCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Lọc chỉ danh mục thuộc type hiện tại (expense/income)
                    final categories = snapshot.data!
                        .where((c) => c.type == _type)
                        .toList();

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.category,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: const Text('Chọn danh mục'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  const Icon(Icons.category, size: 16),
                                  const SizedBox(width: 8),
                                  Text(c.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      // Khi chọn => lưu categoryId
                      onChanged: (val) =>
                          setState(() => _selectedCategoryId = val),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacing),

                // =========================================================
                // WALLET DROPDOWN (theo userId)
                // =========================================================
                Text('Ví thanh toán', style: AppTextStyles.h3),
                const SizedBox(height: AppTheme.spacingSmall),
                StreamBuilder<List<WalletModel>>(
                  // Lấy wallets theo uid (nếu null thì truyền '' => thường sẽ trả empty)
                  stream: _transactionService.getWallets(
                    _authService.currentUser?.uid ?? '',
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final wallets = snapshot.data!;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedWalletId,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.primary,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: const Text('Chọn ví'),
                      items: wallets
                          .map(
                            (w) => DropdownMenuItem(
                              value: w.id,
                              // Hiển thị tên ví + số dư (format #,###)
                              child: Text(
                                '${w.name} (${NumberFormat('#,###').format(w.balance)}đ)',
                              ),
                            ),
                          )
                          .toList(),
                      // Khi chọn => lưu walletId
                      onChanged: (val) =>
                          setState(() => _selectedWalletId = val),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacing),

                // =========================================================
                // DATE-TIME PICKER
                // =========================================================
                Text('Ngày giờ', style: AppTextStyles.h3),
                const SizedBox(height: AppTheme.spacingSmall),
                InkWell(
                  onTap: _pickDate, // mở chọn ngày + giờ
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacing),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadius,
                      ),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppTheme.spacing),
                        // Format hiển thị dd/MM/yyyy HH:mm
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate),
                          style: AppTextStyles.bodyLarge,
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing),

                // =========================================================
                // NOTE
                // =========================================================
                Text('Ghi chú', style: AppTextStyles.h3),
                const SizedBox(height: AppTheme.spacingSmall),
                CustomTextField(
                  controller: _noteController,
                  hint: 'Ghi chú (không bắt buộc)',
                  prefixIcon: Icons.note,
                  maxLines: 3,
                ),
                const SizedBox(height: AppTheme.spacing),

                // =========================================================
                // TAGS
                // =========================================================
                Text('Tags', style: AppTextStyles.h3),
                const SizedBox(height: AppTheme.spacingSmall),
                CustomTextField(
                  controller: _tagsController,
                  hint: 'Cách nhau bởi dấu phẩy',
                  prefixIcon: Icons.tag,
                ),
                const SizedBox(height: AppTheme.spacingLarge * 2),

                // =========================================================
                // SAVE BUTTON
                // =========================================================
                GradientButton(
                  text: widget.transaction == null
                      ? 'Thêm giao dịch'
                      : 'Cập nhật',
                  onPressed: _save,
                  isLoading: _isLoading, // hiện đang luôn false vì biến final
                  gradient: gradient,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

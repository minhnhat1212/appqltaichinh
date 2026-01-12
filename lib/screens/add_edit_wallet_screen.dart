import 'package:flutter/material.dart'; // UI widgets của Flutter
import 'package:flutter/services.dart'; // InputFormatter để giới hạn ký tự nhập
import 'package:firebase_auth/firebase_auth.dart'; // Lấy user đang đăng nhập
import '../models/wallet_model.dart'; // Model ví (WalletModel)
import '../services/wallet_service.dart'; // Service thao tác DB (create/update/delete)
import '../theme.dart'; // Theme chung: màu, spacing, text styles,...

/// Màn hình dùng để:
/// - Tạo ví mới (create mode): widget.wallet == null
/// - Sửa ví (edit mode): widget.wallet != null
class AddEditWalletScreen extends StatefulWidget {
  final WalletModel? wallet; // null = create mode, not null = edit mode

  const AddEditWalletScreen({super.key, this.wallet});

  @override
  State<AddEditWalletScreen> createState() => _AddEditWalletScreenState();
}

class _AddEditWalletScreenState extends State<AddEditWalletScreen> {
  /// Key của Form để validate toàn bộ input
  final _formKey = GlobalKey<FormState>();

  /// Controller để đọc dữ liệu người dùng nhập
  final _nameController = TextEditingController(); // tên ví
  final _balanceController = TextEditingController(); // số dư ban đầu (chỉ create)

  /// Service xử lý CRUD ví với database
  final WalletService _walletService = WalletService();

  /// Lấy uid của user hiện tại (bắt buộc user đã login)
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  /// Icon mặc định của ví (dạng emoji)
  String _selectedIcon = '💰';

  /// Cờ loading để disable thao tác + hiển thị spinner
  bool _isLoading = false;

  /// Danh sách icon emoji có sẵn để chọn
  final List<String> _availableIcons = [
    '💰',
    '💳',
    '🏦',
    '💵',
    '💴',
    '💶',
    '💷',
    '🪙',
    '💼',
    '👛',
    '🏧',
    '💸',
    '🤑',
    '💲',
    '🎯',
  ];

  @override
  void initState() {
    super.initState();

    /// Nếu có wallet truyền vào => đang ở edit mode
    /// => đổ dữ liệu cũ lên form để người dùng chỉnh sửa
    if (widget.wallet != null) {
      _nameController.text = widget.wallet!.name;
      _selectedIcon = widget.wallet!.icon;
      _balanceController.text = widget.wallet!.balance.toString();
      // Lưu ý: balance field trong UI chỉ hiện ở create mode,
      // nhưng vẫn set text ở đây không sao (chỉ để “đủ dữ liệu”).
    }
  }

  @override
  void dispose() {
    /// Dispose controller để tránh rò rỉ bộ nhớ
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  /// Getter tiện dụng để biết đang edit hay create
  bool get _isEditMode => widget.wallet != null;

  /// Xóa ví:
  /// 1) Hỏi confirm
  /// 2) set loading
  /// 3) gọi service delete
  /// 4) đóng màn + snackbar thông báo
  Future<void> _deleteWallet() async {
    // Hộp thoại xác nhận xóa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa ví'),
          content: Text(
            'Bạn có chắc muốn xóa ví "${widget.wallet?.name}"?\n\n'
            'Hành động này không thể hoàn tác.',
          ),
          actions: [
            // Hủy => trả về false
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            // Xóa => trả về true
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

    // Nếu user không đồng ý xóa => thoát
    if (confirm != true) return;

    // Bật loading để disable nút + hiển thị spinner
    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi service xóa ví theo userId + walletId
      await _walletService.deleteWallet(
        userId: _userId,
        walletId: widget.wallet!.id, // edit mode chắc chắn có wallet
      );

      if (mounted) {
        // Đóng màn hình edit
        Navigator.pop(context);

        // Thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa ví thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Nếu lỗi => hiện snackbar báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa ví: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Tắt loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Lưu ví (create hoặc update):
  /// - Validate form
  /// - Bật loading
  /// - Nếu edit: update name + icon (optimistic UI: đóng màn ngay)
  /// - Nếu create: parse balance + create (optimistic UI: đóng màn ngay)
  Future<void> _saveWallet() async {
    // Validate các trường trong Form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Bật loading
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditMode) {
        // =========================
        // EDIT MODE (Update wallet)
        // =========================

        // ✅ Optimistic UI: đóng màn ngay để UX “nhanh”
        if (mounted) {
          Navigator.pop(context);

          // Snackbar thông báo đang cập nhật
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang cập nhật ví...'),
              duration: Duration(milliseconds: 1000),
            ),
          );
        }

        // Chạy update ở “background”
        // (Ở đây bạn catch riêng để tránh crash; nếu muốn có UX tốt hơn
        // thì nên hiện snackbar lỗi khi update thất bại)
        try {
          await _walletService.updateWallet(
            userId: _userId,
            walletId: widget.wallet!.id,
            name: _nameController.text.trim(),
            icon: _selectedIcon,
          );
        } catch (e) {
          debugPrint('Error updating wallet: $e');
        }
      } else {
        // =========================
        // CREATE MODE (Create wallet)
        // =========================

        // Parse số dư ban đầu (rỗng => 0)
        final balance = double.tryParse(_balanceController.text) ?? 0.0;

        // ✅ Optimistic UI: đóng màn ngay cho UX tốt
        if (mounted) {
          Navigator.pop(context);

          // Snackbar “đang tạo”
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang tạo ví...'),
              duration: Duration(milliseconds: 1500),
              backgroundColor: AppColors.primary,
            ),
          );
        }

        // Tạo ví trong “background”
        try {
          await _walletService.createWallet(
            userId: _userId,
            name: _nameController.text.trim(),
            icon: _selectedIcon,
            initialBalance: balance,
          );
        } catch (e) {
          debugPrint('Error creating wallet: $e');
        }
      }
    } catch (e) {
      // Safety net: hiếm khi vào đây vì đã tách try/catch bên trong
      debugPrint('Error in wallet save: $e');
    } finally {
      // Tắt loading (nếu màn hình vẫn còn mounted)
      // Lưu ý: vì optimistic UI đã pop màn hình, đoạn setState này
      // thường sẽ không còn chạy (mounted = false) => an toàn.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nền gradient toàn màn hình
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // =========================
              // Custom AppBar (tự dựng)
              // =========================
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing),
                child: Row(
                  children: [
                    // Nút back
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),

                    // Title theo mode
                    Text(
                      _isEditMode ? 'Chỉnh sửa ví' : 'Tạo ví mới',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // =========================
              // Form Content (phần trắng)
              // =========================
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                      topRight: Radius.circular(AppTheme.borderRadiusLarge),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(AppTheme.spacing),
                      children: [
                        const SizedBox(height: AppTheme.spacing),

                        // =========================
                        // Name field (bắt buộc)
                        // =========================
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên ví',
                            hintText: 'VD: Ví tiền mặt',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          validator: (value) {
                            // Không cho rỗng
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên ví';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppTheme.spacingLarge),

                        // =========================
                        // Icon selector (emoji)
                        // =========================
                        Text(
                          'Chọn icon',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),

                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacing),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), // grid không tự scroll (ListView scroll)
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 5,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                ),
                            itemCount: _availableIcons.length,
                            itemBuilder: (context, index) {
                              final icon = _availableIcons[index];
                              final isSelected = _selectedIcon == icon;

                              return GestureDetector(
                                // Tap để chọn icon
                                onTap: () {
                                  setState(() {
                                    _selectedIcon = icon;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    // Nếu selected => gradient, không selected => nền xám nhạt
                                    gradient: isSelected
                                        ? AppColors.primaryGradient
                                        : null,
                                    color: isSelected
                                        ? null
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadiusSmall,
                                    ),
                                    // Viền highlight khi selected
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      icon,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingLarge),

                        // =========================
                        // Balance field (chỉ create mode)
                        // =========================
                        if (!_isEditMode) ...[
                          TextFormField(
                            controller: _balanceController,
                            decoration: const InputDecoration(
                              labelText: 'Số dư ban đầu',
                              hintText: '0',
                              prefixIcon: Icon(Icons.attach_money),
                              suffixText: '₫',
                            ),
                            keyboardType: TextInputType.number,

                            // Cho phép nhập số có thể có dấu "." và tối đa 2 chữ số sau "."
                            // (Lưu ý nhỏ: regex này chỉ “lọc” theo prefix; có thể cần cải tiến nếu muốn chặt hơn)
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (value) {
                              // Cho phép rỗng (rỗng => 0)
                              if (value != null && value.isNotEmpty) {
                                final balance = double.tryParse(value);
                                if (balance == null) {
                                  return 'Số dư không hợp lệ';
                                }
                                if (balance < 0) {
                                  return 'Số dư phải lớn hơn hoặc bằng 0';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),

                          // Nhắc người dùng: số dư chỉ set khi tạo ví
                          Text(
                            'Lưu ý: Số dư chỉ có thể thiết lập khi tạo ví',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],

                        // =========================
                        // Gợi ý ở edit mode
                        // =========================
                        if (_isEditMode) ...[
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacing),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: AppTheme.spacingSmall),
                                Expanded(
                                  child: Text(
                                    'Bạn chỉ có thể chỉnh sửa tên và icon. Số dư sẽ tự động cập nhật khi có giao dịch.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: AppTheme.spacingLarge * 2),

                        // =========================
                        // Save button
                        // =========================
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              // Nếu loading thì disable tap
                              onTap: _isLoading ? null : _saveWallet,
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                              child: Center(
                                child: _isLoading
                                    // Loading => hiện spinner
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    // Không loading => text
                                    : Text(
                                        _isEditMode ? 'Cập nhật' : 'Tạo ví',
                                        style: AppTextStyles.button.copyWith(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),

                        // =========================
                        // Delete button (chỉ edit mode)
                        // =========================
                        if (_isEditMode) ...[
                          const SizedBox(height: AppTheme.spacing),
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(
                                AppTheme.borderRadius,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                // Nếu loading thì disable tap
                                onTap: _isLoading ? null : _deleteWallet,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadius,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Xóa ví',
                                        style: AppTextStyles.button.copyWith(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

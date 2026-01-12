import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Custom TextField với styling đẹp và consistent
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;
  final bool showPasswordToggle;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.showPasswordToggle = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late bool _obscureText;
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText; // Khởi tạo trạng thái ẩn text (dùng cho password)
    _focusController = AnimationController(
      vsync: this, // Cần để đồng bộ với frame rate
      duration: AppTheme.animationDuration, // Thời gian animation
    );
    _focusAnimation = Tween<double>(
      begin: 1.0, // Kích thước bình thường
      end: 1.02, // Phóng to 2% khi focus
    ).animate(CurvedAnimation(parent: _focusController, curve: Curves.easeOut)); // Đường cong easeOut

    _focusNode.addListener(() { // Lắng nghe thay đổi focus
      setState(() {
        _isFocused = _focusNode.hasFocus; // Cập nhật trạng thái focus
        if (_isFocused) {
          _focusController.forward(); // Bắt đầu animation phóng to khi focus
        } else {
          _focusController.reverse(); // Đảo ngược animation khi mất focus
        }
      });
    });
  }

  @override
  void dispose() {
    _focusController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnimation, // Lắng nghe thay đổi animation
      builder: (context, child) {
        return Transform.scale(scale: _focusAnimation.value, child: child); // Áp dụng scale transformation
      },
      child: AnimatedContainer(
        duration: AppTheme.animationDuration, // Thời gian animation cho container
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius), // Bo góc
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1), // Shadow màu primary nhạt khi focus
                    blurRadius: 12, // Độ mờ
                    offset: const Offset(0, 4), // Độ lệch xuống dưới
                  ),
                ]
              : AppTheme.shadowSmall, // Shadow nhỏ khi không focus
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: _obscureText ? 1 : widget.maxLines,
          enabled: widget.enabled,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: AppTheme.animationDuration,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: Icon(
                          widget.prefixIcon,
                          color: _isFocused
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      );
                    },
                  )
                : null,
            suffixIcon: widget.showPasswordToggle && widget.obscureText // Hiển thị nút toggle password nếu được bật
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility, // Icon ẩn/hiện password
                      color: AppColors.textSecondary, // Màu icon
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText; // Đảo ngược trạng thái ẩn/hiện
                      });
                    },
                  )
                : widget.suffixIcon != null // Sử dụng icon tùy chỉnh nếu có
                ? Icon(widget.suffixIcon, color: AppColors.textSecondary) // Hiển thị icon tùy chỉnh
                : null, // Không có suffix icon
            filled: true,
            fillColor: widget.enabled ? Colors.white : AppColors.surfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// TextField cho Amount (số tiền) với formatting đặc biệt
class AmountTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final void Function(String)? onChanged;

  const AmountTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.onChanged,
  });

  @override
  State<AmountTextField> createState() => _AmountTextFieldState();
}

class _AmountTextFieldState extends State<AmountTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, // Cần để đồng bộ với frame rate
      duration: AppTheme.animationDurationSlow, // Thời gian animation chậm (cho hiệu ứng pulse)
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      // Animation từ kích thước bình thường đến phóng to 5%
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut), // Đường cong easeInOut (mượt)
    );

    _focusNode.addListener(() { // Lắng nghe thay đổi focus
      setState(() {
        _isFocused = _focusNode.hasFocus; // Cập nhật trạng thái focus
        if (_isFocused) {
          _pulseController.repeat(reverse: true); // Lặp lại animation pulse (phóng to thu nhỏ liên tục)
        } else {
          _pulseController.reset(); // Reset về trạng thái ban đầu khi mất focus
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isFocused ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : AppTheme.shadowMedium,
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          onChanged: widget.onChanged,
          style: AppTextStyles.amountLarge.copyWith(
            color: _isFocused ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint ?? '0',
            hintStyle: AppTextStyles.amountLarge.copyWith(
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: _isFocused
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.primary.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              borderSide: const BorderSide(color: AppColors.primary, width: 3),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing,
              vertical: AppTheme.spacingXLarge,
            ),
          ),
        ),
      ),
    );
  }
}

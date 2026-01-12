import 'package:flutter/material.dart';
import '../theme.dart';

/// Gradient Button Widget
/// Widget nút bấm với hiệu ứng gradient và shadow đẹp mắt
class GradientButton extends StatelessWidget {
  final String? text; // Văn bản hiển thị trên nút
  final Widget? child; // Widget tùy chỉnh để hiển thị thay vì text
  final VoidCallback? onPressed; // Callback khi nút được nhấn
  final bool isLoading; // Trạng thái đang loading (hiển thị CircularProgressIndicator)
  final Gradient? gradient; // Gradient màu sắc cho nút
  final double? width; // Chiều rộng của nút
  final double? height; // Chiều cao của nút
  final EdgeInsetsGeometry? padding; // Khoảng cách padding bên trong

  const GradientButton({
    super.key,
    this.text,
    this.child,
    required this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity, // Mặc định chiều rộng full màn hình
      height: height ?? 56, // Mặc định chiều cao 56
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient, // Sử dụng gradient mặc định nếu không có gradient tùy chỉnh
        borderRadius: BorderRadius.circular(AppTheme.borderRadius), // Bo góc theo theme
        boxShadow: onPressed != null && !isLoading // Chỉ hiển thị shadow khi nút có thể bấm được và không đang loading
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3), // Màu shadow với độ trong suốt 30%
                  blurRadius: 12, // Độ mờ của shadow
                  offset: const Offset(0, 6), // Độ lệch shadow xuống dưới 6px
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent, // Material trong suốt để InkWell hoạt động
        child: InkWell(
          onTap: isLoading ? null : onPressed, // Vô hiệu hóa tap khi đang loading
          borderRadius: BorderRadius.circular(AppTheme.borderRadius), // Bo góc cho hiệu ứng ripple
          child: Container(
            padding:
                padding ?? // Sử dụng padding tùy chỉnh hoặc padding mặc định
                const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing, // Padding ngang theo theme
                  vertical: AppTheme.spacingSmall, // Padding dọc nhỏ theo theme
                ),
            child: Center(
              child: isLoading // Hiển thị loading indicator nếu đang loading
                  ? const SizedBox(
                      width: 24, // Kích thước loading indicator
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white, // Màu trắng cho indicator
                        strokeWidth: 2.5, // Độ dày của đường vẽ
                      ),
                    )
                  : child ?? // Sử dụng widget tùy chỉnh nếu có
                        Text(
                          text ?? '', // Hiển thị text nếu có
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white, // Màu chữ trắng
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outline Gradient Button Widget
/// Nút bấm với viền (outline) thay vì nền đầy, có thể hiển thị icon
class OutlineGradientButton extends StatelessWidget {
  final String text; // Văn bản hiển thị (bắt buộc)
  final IconData? icon; // Icon hiển thị bên trái text (tùy chọn)
  final VoidCallback? onPressed; // Callback khi nút được nhấn
  final Gradient? gradient; // Gradient (hiện tại chưa sử dụng)
  final double? width; // Chiều rộng của nút
  final double? height; // Chiều cao của nút

  const OutlineGradientButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.gradient,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity, // Mặc định full width
      height: height ?? 56, // Mặc định height 56
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius), // Bo góc
        border: Border.all(color: AppColors.primary, width: 2), // Viền màu primary với độ dày 2px
      ),
      child: Material(
        color: Colors.transparent, // Material trong suốt
        child: InkWell(
          onTap: onPressed, // Xử lý sự kiện tap
          borderRadius: BorderRadius.circular(AppTheme.borderRadius), // Bo góc cho ripple effect
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing, // Padding ngang
              vertical: AppTheme.spacingSmall, // Padding dọc
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung
              children: [
                if (icon != null) ...[ // Hiển thị icon nếu có
                  Icon(icon, color: AppColors.primary, size: 24), // Icon với màu primary
                  const SizedBox(width: AppTheme.spacingSmall), // Khoảng cách giữa icon và text
                ],
                Text(
                  text, // Hiển thị text
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary, // Màu chữ primary
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon Button with Gradient Background
/// Nút icon tròn với nền gradient và shadow
class GradientIconButton extends StatelessWidget {
  final IconData icon; // Icon hiển thị (bắt buộc)
  final VoidCallback? onPressed; // Callback khi nút được nhấn
  final Gradient? gradient; // Gradient màu sắc cho nút
  final double size; // Kích thước của nút (chiều rộng và chiều cao bằng nhau)
  final Color? iconColor; // Màu của icon

  const GradientIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.size = 48, // Mặc định kích thước 48x48
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, // Chiều rộng bằng size
      height: size, // Chiều cao bằng size (tạo hình vuông)
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient, // Sử dụng gradient mặc định nếu không có
        shape: BoxShape.circle, // Hình dạng tròn
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3), // Màu shadow
            blurRadius: 8, // Độ mờ shadow
            offset: const Offset(0, 4), // Độ lệch shadow xuống dưới 4px
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, // Material trong suốt
        child: InkWell(
          onTap: onPressed, // Xử lý sự kiện tap
          customBorder: const CircleBorder(), // Border tròn cho ripple effect
          child: Center(
            child: Icon(
              icon, // Icon hiển thị
              color: iconColor ?? Colors.white, // Màu trắng mặc định nếu không có màu tùy chỉnh
              size: size * 0.5, // Kích thước icon bằng 50% kích thước nút
            ),
          ),
        ),
      ),
    );
  }
}

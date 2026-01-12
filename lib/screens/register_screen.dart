import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_text_field.dart';

/// Màn hình đăng ký tài khoản mới
/// Cho phép người dùng tạo tài khoản với email và password
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // Controllers quản lý nhập liệu
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.animationDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Xử lý đăng ký tài khoản
  Future<void> _register() async {
    // 1. Kiểm tra các trường nhập liệu có trống không
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 2. Kiểm tra mật khẩu xác nhận có khớp không
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu không khớp'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 3. Kiểm tra độ dài mật khẩu (tối thiểu 6 ký tự)
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu phải có ít nhất 6 ký tự'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Gọi service đăng ký
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Đăng ký thành công, quay về màn hình trước đó (thường là Login hoặc Welcome)
      // Lưu ý: Nếu App thiết kế đăng ký xong tự login thì logic này có thể thay đổi
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          iconSize: 28,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing),

                      // Logo/Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusLarge,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add,
                          size: 50,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Title
                      Text(
                        'Tạo Tài Khoản',
                        style: AppTextStyles.h1.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      Text(
                        'Đăng ký để bắt đầu quản lý tài chính',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingLarge * 2),

                      // Form Container
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLarge),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email Field
                            CustomTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'example@email.com',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: AppTheme.spacing),

                            // Password Field
                            CustomTextField(
                              controller: _passwordController,
                              label: 'Mật khẩu',
                              hint: 'Tối thiểu 6 ký tự',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              showPasswordToggle: true,
                            ),
                            const SizedBox(height: AppTheme.spacing),

                            // Confirm Password Field
                            CustomTextField(
                              controller: _confirmPasswordController,
                              label: 'Xác nhận mật khẩu',
                              hint: 'Nhập lại mật khẩu',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              showPasswordToggle: true,
                            ),
                            const SizedBox(height: AppTheme.spacingLarge),

                            // Register Button
                            GradientButton(
                              text: 'Đăng Ký',
                              onPressed: _register,
                              isLoading: _isLoading,
                              gradient: AppColors.secondaryGradient,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Đã có tài khoản? ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Đăng nhập',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

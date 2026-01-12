import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

/// Màn hình đăng nhập
/// Cho phép người dùng đăng nhập bằng email/password hoặc Google Sign In
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controller để quản lý input của email và password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Service xử lý xác thực (đăng nhập, đăng ký)
  final _authService = AuthService();

  // Biến trạng thái để hiển thị loading khi đang xử lý đăng nhập
  bool _isLoading = false;

  // Các biến cho Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation; // Hiệu ứng mờ dần
  late Animation<Offset> _slideAnimation; // Hiệu ứng trượt lên

  @override
  @override
  void initState() {
    super.initState();
    // Khởi tạo AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.animationDuration,
    );

    // Config hiệu ứng Fade (mờ dần từ 0 -> 1)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Config hiệu ứng Slide (trượt từ dưới lên)
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    // Bắt đầu chạy animation khi màn hình được tạo
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý đăng nhập bằng Email/Password
  Future<void> _login() async {
    // Validate: Kiểm tra input rỗng
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    // Bắt đầu loading
    setState(() => _isLoading = true);
    try {
      // Gọi service đăng nhập
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Nếu thành công, StreamBuilder ở main.dart sẽ tự động điều hướng vào App
    } catch (e) {
      // Hiển thị lỗi nếu đăng nhập thất bại
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // Tắt loading dù thành công hay thất bại
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Xử lý đăng nhập bằng Google
  Future<void> _loginGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // Tương tự, StreamBuilder sẽ lo việc điều hướng
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập Google thất bại: ${e.toString()}'),
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
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                          Icons.account_balance_wallet,
                          size: 50,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Title
                      Text(
                        'Quản Lý Tài Chính',
                        style: AppTextStyles.h1.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      Text(
                        'Đăng nhập để tiếp tục',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
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
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline,
                              obscureText: true,
                              showPasswordToggle: true,
                            ),
                            const SizedBox(height: AppTheme.spacingSmall),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Quên mật khẩu?',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacing),

                            // Login Button
                            GradientButton(
                              text: 'Đăng Nhập',
                              onPressed: _login,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: AppTheme.spacing),

                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacing,
                                  ),
                                  child: Text(
                                    'HOẶC',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacing),

                            // Google Sign In
                            OutlineGradientButton(
                              text: 'Đăng nhập với Google',
                              icon: Icons.g_mobiledata,
                              onPressed: _isLoading ? null : _loginGoogle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Chưa có tài khoản? ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Đăng ký',
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

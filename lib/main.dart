import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // ✅ Bắt buộc trước khi init Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Khởi tạo Firebase theo cấu hình flutterfire
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const UngDung());
}

class UngDung extends StatelessWidget {
  const UngDung({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản Lý Tài Chính',
      theme: AppTheme.lightTheme,
      home: StreamBuilder(
        // ✅ Theo dõi trạng thái đăng nhập
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          // ✅ Đang load trạng thái đăng nhập
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            );
          }

          // ✅ Chưa đăng nhập
          if (!snapshot.hasData) return const LoginScreen();

          // ✅ Đã đăng nhập -> vào trang chủ
          return HomeScreen(uid: snapshot.data!.uid);
        },
      ),
    );
  }
}

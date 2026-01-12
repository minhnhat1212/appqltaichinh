import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../theme.dart';
import 'add_edit_wallet_screen.dart';

/// Màn hình danh sách ví
/// Hiển thị tất cả ví của người dùng với số dư và khả năng thêm/sửa/xóa ví
class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  final WalletService _walletService = WalletService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ví của tôi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Wallet List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.borderRadiusLarge),
                      topRight: Radius.circular(AppTheme.borderRadiusLarge),
                    ),
                  ),
                  child: StreamBuilder<List<WalletModel>>(
                    // Stream lắng nghe thay đổi danh sách ví từ Firestore theo userId
                    stream: _walletService.getWallets(_userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Lỗi: ${snapshot.error}'));
                      }

                      final wallets = snapshot.data ?? [];

                      if (wallets.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có ví nào',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nhấn nút + để tạo ví mới',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacing),
                        itemCount: wallets.length,
                        itemBuilder: (context, index) {
                          // Build từng item card ví với hiệu ứng staggered
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            // Delay trễ dần theo index: index * 100ms
                            duration: Duration(
                              milliseconds: 400 + (index * 100),
                            ),
                            curve: Curves.easeOutQuad,
                            builder: (context, value, child) {
                              return Transform.translate(
                                // Trượt từ dưới lên 50px
                                offset: Offset(0, 50 * (1 - value)),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: _buildWalletCard(wallets[index]),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditWalletScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWalletCard(WalletModel wallet) {
    final numberFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Dismissible(
      key: Key(wallet.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacing),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: Text('Bạn có chắc muốn xóa ví "${wallet.name}"?'),
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
      },
      onDismissed: (direction) async {
        try {
          await _walletService.deleteWallet(
            userId: _userId,
            walletId: wallet.id,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xóa ví thành công'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi xóa ví: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditWalletScreen(wallet: wallet),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      wallet.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spacing),

                // Name & Balance
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wallet.name, style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text(
                        numberFormat.format(wallet.balance),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: wallet.balance >= 0
                              ? AppColors.income
                              : AppColors.expense,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Icon
                Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

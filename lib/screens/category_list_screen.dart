import 'package:flutter/material.dart'; // UI Flutter
import '../models/category_model.dart'; // Model danh mục (CategoryModel)
import '../services/transaction_service.dart'; // Service lấy/xóa danh mục
import '../theme.dart'; // Theme chung: màu, spacing, text styles
import 'add_edit_category_screen.dart'; // Màn hình tạo/sửa danh mục

/// Màn hình danh sách danh mục:
/// - Tab 1: Chi tiêu (expense)
/// - Tab 2: Thu nhập (income)
/// - FAB: tạo danh mục mới theo tab hiện tại
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  /// Service thao tác category (stream categories + delete)
  final TransactionService _transactionService = TransactionService();

  /// TabController quản lý TabBar và TabBarView
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController cho 2 tab: Chi tiêu & Thu nhập
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Dispose để tránh leak
    _tabController.dispose();
    super.dispose();
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
                    // Nút quay lại
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Danh mục',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // =========================
              // Tab Bar (Chi tiêu / Thu nhập)
              // =========================
              Container(
                // nền trắng mờ để tab nổi trên gradient
                color: Colors.white.withOpacity(0.1),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white, // gạch chân tab đang chọn
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Chi tiêu'),
                    Tab(text: 'Thu nhập'),
                  ],
                ),
              ),

              // =========================
              // Tab content: danh sách danh mục
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
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: danh mục expense
                      _buildCategoryList('expense'),

                      // Tab 2: danh mục income
                      _buildCategoryList('income'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // =========================
      // FAB: tạo danh mục mới theo tab hiện tại
      // =========================
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // tab 0 => expense, tab 1 => income
          final type = _tabController.index == 0 ? 'expense' : 'income';

          Navigator.push(
            context,
            MaterialPageRoute(
              // AddEditCategoryScreen nhận type để tạo đúng loại danh mục
              builder: (context) => AddEditCategoryScreen(type: type),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build list danh mục theo type (expense/income)
  Widget _buildCategoryList(String type) {
    return StreamBuilder<List<CategoryModel>>(
      // Stream lấy tất cả categories (cả expense và income)
      stream: _transactionService.getCategories(),
      builder: (context, snapshot) {
        // Đang load dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Có lỗi
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        // Lấy danh sách, nếu null thì mặc định list rỗng
        final allCategories = snapshot.data ?? [];

        // Lọc danh sách theo type (expense/income) tương ứng với tab hiện tại
        final categories = allCategories.where((c) => c.type == type).toList();

        // Nếu rỗng => empty state
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có danh mục nào',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn nút + để tạo danh mục mới',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          );
        }

        // Có dữ liệu => list
        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacing),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return _buildCategoryCard(categories[index]);
          },
        );
      },
    );
  }

  /// 1 card danh mục:
  /// - Bọc Dismissible để vuốt sang trái xóa
  /// - Tap để sửa (mở AddEditCategoryScreen)
  Widget _buildCategoryCard(CategoryModel category) {
    return Dismissible(
      key: Key(category.id), // key duy nhất để Flutter quản lý item
      background: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing),
        decoration: BoxDecoration(
          color: AppColors.error, // nền đỏ khi vuốt xóa
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacing),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      direction: DismissDirection.endToStart, // chỉ cho vuốt từ phải sang trái
      // Show Dialog xác nhận trước khi xóa
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: Text(
                'Bạn có chắc muốn xóa danh mục "${category.name}"?',
              ),
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

      // Khi đã confirm và item bị dismiss => gọi delete
      onDismissed: (direction) async {
        try {
          await _transactionService.deleteCategory(category.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã xóa danh mục thành công'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          // Nếu lỗi thì báo lỗi (lưu ý: item đã bị dismiss khỏi UI)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi khi xóa danh mục: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },

      // Nội dung card
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing),
        child: InkWell(
          // Tap để sửa danh mục
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditCategoryScreen(category: category),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing),
            child: Row(
              children: [
                // =========================
                // Icon box
                // =========================
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    // Gradient theo type (income/expense)
                    gradient: category.type == 'income'
                        ? AppColors.incomeGradient
                        : AppColors.expenseGradient,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusSmall,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      // Convert iconName (string) -> IconData
                      _getIconData(category.icon),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(width: AppTheme.spacing),

                // =========================
                // Name + Type badge
                // =========================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên danh mục
                      Text(category.name, style: AppTextStyles.h3),
                      const SizedBox(height: 4),

                      // Badge "Thu nhập" / "Chi tiêu"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: category.type == 'income'
                              ? AppColors.income.withOpacity(0.1)
                              : AppColors.expense.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                        ),
                        child: Text(
                          category.type == 'income' ? 'Thu nhập' : 'Chi tiêu',
                          style: AppTextStyles.caption.copyWith(
                            color: category.type == 'income'
                                ? AppColors.income
                                : AppColors.expense,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Icon chỉ hướng để gợi ý có thể bấm vào
                Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Convert iconName (string lưu DB) -> IconData để hiển thị
  /// Nếu không match thì trả về Icons.category mặc định
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'attach_money':
        return Icons.attach_money;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'home':
        return Icons.home;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school;
      case 'medical_services':
        return Icons.medical_services;
      case 'movie':
        return Icons.movie;
      case 'flight':
        return Icons.flight;
      case 'work':
        return Icons.work;
      case 'account_balance':
        return Icons.account_balance;
      case 'trending_up':
        return Icons.trending_up;
      case 'savings':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }
}

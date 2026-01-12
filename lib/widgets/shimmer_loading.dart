import 'package:flutter/material.dart';
import '../theme.dart';

/// Shimmer Loading Placeholders
/// Các widget hiển thị hiệu ứng shimmer (loading animation) trong khi chờ dữ liệu

/// Widget hiển thị shimmer loading cho Transaction Card
/// Mô phỏng layout của TransactionCard với các box shimmer
class TransactionCardShimmer extends StatelessWidget {
  const TransactionCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing,
        vertical: AppTheme.spacingSmall / 2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing),
        child: Row(
          children: [
            // Icon shimmer
            ShimmerBox(
              width: 56,
              height: 56,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            const SizedBox(width: AppTheme.spacing),
            // Content shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                    width: double.infinity,
                    height: 16,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: 120,
                    height: 12,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            // Amount shimmer
            ShimmerBox(
              width: 80,
              height: 20,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị shimmer loading cho Balance Summary Card
/// Mô phỏng layout của BalanceSummaryCard với các box shimmer
class BalanceCardShimmer extends StatelessWidget {
  const BalanceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(
            width: 100,
            height: 14,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          ShimmerBox(
            width: 200,
            height: 36,
            borderRadius: AppTheme.borderRadiusSmall,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: 80,
                      height: 12,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: 120,
                      height: 20,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(
                      width: 80,
                      height: 12,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: 120,
                      height: 20,
                      borderRadius: AppTheme.borderRadiusSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget shimmer box có thể tái sử dụng
/// Hiển thị hiệu ứng shimmer animation (gradient di chuyển) để tạo hiệu ứng loading
class ShimmerBox extends StatefulWidget {
  final double width; // Chiều rộng của box
  final double height; // Chiều cao của box
  final double borderRadius; // Bán kính bo góc

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppTheme.borderRadiusSmall,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controller điều khiển animation shimmer

  @override
  void initState() {
    super.initState();
    // Tạo animation controller để điều khiển hiệu ứng shimmer
    _controller = AnimationController(
      vsync: this, // Cần để đồng bộ với frame rate
      duration: AppTheme.shimmerDuration, // Thời gian một chu kỳ shimmer (thường là 1-2 giây)
    )..repeat(); // Lặp lại liên tục (không dừng)
  }

  @override
  void dispose() {
    _controller.dispose(); // Giải phóng controller khi widget bị hủy
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller, // Lắng nghe thay đổi của controller
      builder: (context, child) {
        return Container(
          width: widget.width, // Chiều rộng từ props
          height: widget.height, // Chiều cao từ props
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius), // Bo góc
            gradient: LinearGradient(
              colors: const [
                AppColors.shimmerBase, // Màu nền tối (màu gốc)
                AppColors.shimmerHighlight, // Màu highlight sáng (màu sáng nhất)
                AppColors.shimmerBase, // Màu nền tối (quay lại màu gốc)
              ],
              stops: [
                _controller.value - 0.3, // Stop đầu (di chuyển theo animation, trừ 0.3 để tạo hiệu ứng mờ dần)
                _controller.value, // Stop giữa (vị trí highlight, di chuyển từ 0 đến 1)
                _controller.value + 0.3, // Stop cuối (di chuyển theo animation, cộng 0.3 để tạo hiệu ứng mờ dần)
              ],
              begin: Alignment.topLeft, // Bắt đầu từ góc trên trái
              end: Alignment.bottomRight, // Kết thúc ở góc dưới phải (hiệu ứng chéo)
            ),
          ),
        );
      },
    );
  }
}

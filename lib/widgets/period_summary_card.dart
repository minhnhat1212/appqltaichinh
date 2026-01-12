import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/statistics_data.dart';

/// Widget hiển thị tổng kết theo khoảng thời gian (ngày/tuần/tháng/năm)
/// Cho phép chọn period và hiển thị thu nhập, chi tiêu, và số dư ròng
class PeriodSummaryCard extends StatelessWidget {
  final PeriodSummary summary;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const PeriodSummaryCard({
    super.key,
    required this.summary,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi',
      symbol: '₫',
    ); // Format tiền tệ VNĐ

    return Container(
      margin: const EdgeInsets.all(16), // Margin 16px tất cả các phía
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(
              context,
            ).primaryColor.withOpacity(0.8), // Màu primary đậm hơn
            Theme.of(context).primaryColor.withOpacity(
              0.6,
            ), // Màu primary nhạt hơn (tạo gradient)
          ],
          begin: Alignment.topLeft, // Bắt đầu từ góc trên trái
          end: Alignment.bottomRight, // Kết thúc ở góc dưới phải
        ),
        borderRadius: BorderRadius.circular(20), // Bo góc 20px
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(
              0.3,
            ), // Shadow màu primary với độ trong suốt 30%
            blurRadius: 20, // Độ mờ shadow
            offset: const Offset(0, 10), // Độ lệch shadow xuống dưới 10px
          ),
        ],
      ),
      child: Column(
        children: [
          // Period Selector - Bộ chọn khoảng thời gian
          Padding(
            padding: const EdgeInsets.all(16), // Padding 16px
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround, // Căn đều các nút
              children: [
                _buildPeriodButton(
                  context,
                  'Ngày',
                  'day',
                ), // Nút chọn theo ngày
                _buildPeriodButton(
                  context,
                  'Tuần',
                  'week',
                ), // Nút chọn theo tuần
                _buildPeriodButton(
                  context,
                  'Tháng',
                  'month',
                ), // Nút chọn theo tháng
                _buildPeriodButton(context, 'Năm', 'year'), // Nút chọn theo năm
              ],
            ),
          ),

          // Summary Values - Các giá trị tổng kết
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ), // Padding ngang 24px, dọc 16px
            child: Column(
              children: [
                _buildSummaryRow(
                  context,
                  'Thu nhập', // Nhãn
                  summary.income, // Số tiền thu nhập
                  Icons.trending_up, // Icon mũi tên lên
                  Colors.green[300]!, // Màu xanh lá
                  currencyFormat, // Format tiền tệ
                ),
                const SizedBox(height: 12), // Khoảng cách 12px
                _buildSummaryRow(
                  context,
                  'Chi tiêu', // Nhãn
                  summary.expense, // Số tiền chi tiêu
                  Icons.trending_down, // Icon mũi tên xuống
                  Colors.red[300]!, // Màu đỏ
                  currencyFormat,
                ),
                const SizedBox(height: 12),
                const Divider(
                  color: Colors.white30,
                ), // Đường phân cách màu trắng nhạt
                const SizedBox(height: 12),
                _buildSummaryRow(
                  context,
                  'Ròng', // Nhãn số dư ròng
                  summary.net, // Số dư ròng (thu nhập - chi tiêu)
                  Icons.account_balance_wallet, // Icon ví
                  summary.net >= 0
                      ? Colors.green[300]!
                      : Colors.red[300]!, // Màu xanh nếu dương, đỏ nếu âm
                  currencyFormat,
                  isNet: true, // Đánh dấu đây là số dư ròng (hiển thị đậm hơn)
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng nút chọn khoảng thời gian (ngày/tuần/tháng/năm)
  /// period: 'day', 'week', 'month', hoặc 'year'
  Widget _buildPeriodButton(BuildContext context, String label, String period) {
    final isSelected =
        selectedPeriod == period; // Kiểm tra period có đang được chọn không

    return GestureDetector(
      onTap: () => onPeriodChanged(period), // Gọi callback khi nút được nhấn
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 300,
        ), // Thời gian animation 300ms
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ), // Padding ngang 20px, dọc 10px
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(
                  0.2,
                ), // Nền trắng nếu được chọn, trắng nhạt nếu không
          borderRadius: BorderRadius.circular(20), // Bo góc 20px
          boxShadow:
              isSelected // Chỉ hiển thị shadow khi được chọn
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(
                      0.3,
                    ), // Shadow trắng với độ trong suốt 30%
                    blurRadius: 8, // Độ mờ
                    offset: const Offset(0, 4), // Độ lệch xuống dưới 4px
                  ),
                ]
              : [], // Không có shadow khi không được chọn
        ),
        child: Text(
          label, // Text hiển thị (ví dụ: 'Ngày', 'Tuần')
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.white, // Màu primary nếu được chọn, trắng nếu không
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal, // Chữ đậm nếu được chọn
            fontSize: 14, // Kích thước chữ
          ),
        ),
      ),
    );
  }

  /// Xây dựng một dòng hiển thị thông tin tổng kết (thu nhập/chi tiêu/số dư ròng)
  /// isNet: true nếu là số dư ròng (cần hiển thị đậm hơn)
  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
    NumberFormat currencyFormat, {
    bool isNet = false, // Đánh dấu có phải số dư ròng không
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8), // Padding 8px
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              0.2,
            ), // Nền trắng nhạt (độ trong suốt 20%)
            borderRadius: BorderRadius.circular(12), // Bo góc 12px
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ), // Icon với màu và kích thước tùy chỉnh
        ),
        const SizedBox(width: 12), // Khoảng cách giữa icon và text
        Expanded(
          child: Text(
            label, // Nhãn (ví dụ: 'Thu nhập', 'Chi tiêu', 'Ròng')
            style: TextStyle(
              color: Colors.white.withOpacity(
                0.9,
              ), // Màu trắng với độ trong suốt 90%
              fontSize: isNet ? 18 : 16, // Font lớn hơn nếu là số dư ròng
              fontWeight: isNet
                  ? FontWeight.bold
                  : FontWeight.normal, // Chữ đậm nếu là số dư ròng
            ),
          ),
        ),
        // Sử dụng TweenAnimationBuilder để tạo hiệu ứng nhảy số
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: amount),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutExpo, // Hiệu ứng chậm dần ở cuối
          builder: (context, value, child) {
            return Text(
              currencyFormat.format(value),
              style: TextStyle(
                color: Colors.white,
                fontSize: isNet ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ],
    );
  }
}

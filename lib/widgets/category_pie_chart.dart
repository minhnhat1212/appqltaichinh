import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/statistics_data.dart';

/// Widget hiển thị biểu đồ tròn (Pie Chart) cho chi tiêu theo danh mục
/// Sử dụng thư viện fl_chart để vẽ biểu đồ tròn với tương tác touch
class CategoryPieChart extends StatefulWidget {
  final List<CategorySpending> categoryData;

  const CategoryPieChart({super.key, required this.categoryData});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int touchedIndex = -1; // Index của phần được chạm trong biểu đồ tròn (-1 nghĩa là không có phần nào được chạm)

  @override
  Widget build(BuildContext context) {
    if (widget.categoryData.isEmpty) { // Kiểm tra nếu không có dữ liệu
      return _buildEmptyState(); // Hiển thị trạng thái rỗng
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiêu theo danh mục',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Callback khi người dùng chạm vào biểu đồ tròn
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              // Nếu không có phần nào được chạm, đặt touchedIndex = -1
                              touchedIndex = -1;
                              return;
                            }
                            // Lưu index của phần được chạm để highlight
                            touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false), // Không hiển thị border
                      sectionsSpace: 2, // Khoảng cách giữa các phần là 2px
                      centerSpaceRadius: 40, // Bán kính khoảng trống ở giữa (tạo hình donut)
                      sections: _buildSections(), // Danh sách các phần của biểu đồ
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _buildLegend()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tạo danh sách các phần (sections) cho biểu đồ tròn
  /// Mỗi phần đại diện cho một danh mục chi tiêu
  List<PieChartSectionData> _buildSections() {
    return widget.categoryData.asMap().entries.map((entry) {
      final index = entry.key; // Index của danh mục trong danh sách
      final data = entry.value; // Dữ liệu chi tiêu của danh mục (CategorySpending)
      final isTouched = index == touchedIndex; // Kiểm tra phần có đang được chạm không
      final radius = isTouched ? 70.0 : 60.0; // Tăng bán kính 10px khi được chạm (hiệu ứng highlight)
      final fontSize = isTouched ? 16.0 : 14.0; // Tăng kích thước font khi được chạm

      return PieChartSectionData(
        color: data.color, // Màu sắc của phần (từ CategorySpending)
        value: data.amount, // Giá trị (số tiền chi tiêu) để tính tỉ lệ
        title: '${data.percentage.toStringAsFixed(1)}%', // Hiển thị phần trăm với 1 chữ số thập phân
        radius: radius, // Bán kính của phần (lớn hơn khi được chạm)
        titleStyle: TextStyle(
          fontSize: fontSize, // Kích thước chữ (lớn hơn khi được chạm)
          fontWeight: FontWeight.bold, // Chữ đậm
          color: Colors.white, // Màu chữ trắng
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)], // Shadow đen nhạt để dễ đọc
        ),
      );
    }).toList();
  }

  /// Xây dựng chú giải (legend) hiển thị danh mục và màu sắc tương ứng
  /// Giới hạn hiển thị 6 danh mục đầu tiên
  Widget _buildLegend() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.categoryData.take(6).map((data) { // Chỉ hiển thị 6 danh mục đầu
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: data.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.categoryName,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Hiển thị trạng thái rỗng khi chưa có dữ liệu
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

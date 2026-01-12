import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/statistics_data.dart';

/// Widget hiển thị biểu đồ thu nhập vs chi tiêu theo thời gian
/// Hỗ trợ chuyển đổi giữa biểu đồ cột (bar chart) và biểu đồ đường (line chart)
class IncomeExpenseChart extends StatefulWidget {
  final List<TimeSeriesData> timeSeriesData;
  final bool isBarChart; // true for bar chart, false for line chart

  const IncomeExpenseChart({
    super.key,
    required this.timeSeriesData,
    this.isBarChart = true,
  });

  @override
  State<IncomeExpenseChart> createState() => _IncomeExpenseChartState();
}

class _IncomeExpenseChartState extends State<IncomeExpenseChart> {
  bool _isBarChart =
      true; // Loại biểu đồ: true = cột (bar chart), false = đường (line chart)

  @override
  void initState() {
    super.initState();
    _isBarChart = widget.isBarChart; // Khởi tạo loại biểu đồ từ props
  }

  @override
  Widget build(BuildContext context) {
    if (widget.timeSeriesData.isEmpty) {
      // Kiểm tra nếu không có dữ liệu
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thu nhập vs Chi tiêu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Row(
                children: [
                  _buildChartTypeButton(Icons.bar_chart, true),
                  const SizedBox(width: 8),
                  _buildChartTypeButton(Icons.show_chart, false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: _isBarChart ? _buildBarChart() : _buildLineChart(),
          ),
          const SizedBox(height: 16),
          _buildLegend(),
        ],
      ),
    );
  }

  /// Xây dựng nút chuyển đổi loại biểu đồ
  /// isBar: true cho biểu đồ cột, false cho biểu đồ đường
  Widget _buildChartTypeButton(IconData icon, bool isBar) {
    final isSelected =
        _isBarChart == isBar; // Kiểm tra nút có đang được chọn không

    return GestureDetector(
      onTap: () {
        setState(() {
          _isBarChart = isBar;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }

  /// Xây dựng biểu đồ cột (Bar Chart) hiển thị thu nhập và chi tiêu
  Widget _buildBarChart() {
    final maxY =
        _getMaxValue() *
        1.2; // Tăng 20% để có khoảng trống phía trên (cho đẹp hơn)

    // OPTIMIZED: Tính interval động để tránh chồng lấn nhãn ngày
    // Chia cho 6 để hiển thị tối đa khoảng 6-7 nhãn trên trục ngang
    double interval = widget.timeSeriesData.length > 7
        ? (widget.timeSeriesData.length / 6).ceilToDouble()
        : 1.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = widget.timeSeriesData[groupIndex];
              final value = rodIndex == 0 ? data.income : data.expense;
              final label = rodIndex == 0 ? 'Thu' : 'Chi';
              return BarTooltipItem(
                '$label: ${NumberFormat.compact(locale: 'vi').format(value)}₫',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval, // Sử dụng interval động
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= widget.timeSeriesData.length) {
                  return const SizedBox();
                }
                final date = widget.timeSeriesData[value.toInt()].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compact(locale: 'vi').format(value),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 5 : 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
          },
        ),
        barGroups: _buildBarGroups(),
      ),
    );
  }

  /// Xây dựng biểu đồ đường (Line Chart) hiển thị thu nhập và chi tiêu
  Widget _buildLineChart() {
    final maxY = _getMaxValue() * 1.2; // Tăng 20% để có khoảng trống phía trên

    // OPTIMIZED: Tính interval động tương tự BarChart
    double interval = widget.timeSeriesData.length > 7
        ? (widget.timeSeriesData.length / 6).ceilToDouble()
        : 1.0;

    return LineChart(
      LineChartData(
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final data = widget.timeSeriesData[spot.x.toInt()];
                final isIncome = spot.barIndex == 0;
                final value = isIncome ? data.income : data.expense;
                return LineTooltipItem(
                  '${isIncome ? "Thu" : "Chi"}: ${NumberFormat.compact(locale: 'vi').format(value)}₫',
                  TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval, // Sử dụng interval động
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= widget.timeSeriesData.length) {
                  return const SizedBox();
                }
                final date = widget.timeSeriesData[value.toInt()].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('dd/MM').format(date),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  NumberFormat.compact(locale: 'vi').format(value),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 5 : 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
          },
        ),
        lineBarsData: _buildLineChartData(),
      ),
    );
  }

  /// Tạo danh sách nhóm cột cho biểu đồ cột
  /// Mỗi nhóm có 2 cột: thu nhập (xanh) và chi tiêu (đỏ)
  List<BarChartGroupData> _buildBarGroups() {
    return widget.timeSeriesData.asMap().entries.map((entry) {
      final index = entry.key; // Index trên trục X (thứ tự thời gian)
      final data = entry.value; // Dữ liệu thời gian (TimeSeriesData)

      return BarChartGroupData(
        x: index, // Vị trí trên trục X
        barRods: [
          BarChartRodData(
            toY: data.income, // Chiều cao cột = số tiền thu nhập
            color: Colors.green[400], // Màu xanh lá cho thu nhập
            width: 12, // Chiều rộng cột 12px
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6), // Bo góc trên trái
              topRight: Radius.circular(6), // Bo góc trên phải
            ),
          ),
          BarChartRodData(
            toY: data.expense, // Chiều cao cột = số tiền chi tiêu
            color: Colors.red[400], // Màu đỏ cho chi tiêu
            width: 12, // Chiều rộng cột 12px
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6), // Bo góc trên trái
              topRight: Radius.circular(6), // Bo góc trên phải
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Tạo dữ liệu cho biểu đồ đường
  /// Bao gồm 2 đường: thu nhập (xanh) và chi tiêu (đỏ)
  List<LineChartBarData> _buildLineChartData() {
    return [
      // Đường thu nhập (màu xanh)
      LineChartBarData(
        spots: widget.timeSeriesData
            .asMap()
            .entries
            .map(
              (e) => FlSpot(e.key.toDouble(), e.value.income),
            ) // Tạo điểm với X = index, Y = thu nhập
            .toList(), // Chuyển thành danh sách các điểm
        isCurved: true, // Đường cong (mượt) thay vì đường thẳng
        color: Colors.green[400], // Màu xanh lá
        barWidth: 3, // Độ dày đường 3px
        isStrokeCapRound: true, // Đầu đường bo tròn
        dotData: const FlDotData(
          show: true,
        ), // Hiển thị chấm tròn tại mỗi điểm dữ liệu
        belowBarData: BarAreaData(
          show: true, // Hiển thị vùng tô màu phía dưới đường
          color: Colors.green.withOpacity(
            0.1,
          ), // Màu xanh nhạt (độ trong suốt 10%)
        ),
      ),
      // Đường chi tiêu (màu đỏ)
      LineChartBarData(
        spots: widget.timeSeriesData
            .asMap()
            .entries
            .map(
              (e) => FlSpot(e.key.toDouble(), e.value.expense),
            ) // Tạo điểm với X = index, Y = chi tiêu
            .toList(),
        isCurved: true, // Đường cong
        color: Colors.red[400], // Màu đỏ
        barWidth: 3, // Độ dày đường 3px
        isStrokeCapRound: true, // Đầu đường bo tròn
        dotData: const FlDotData(show: true), // Hiển thị chấm tròn
        belowBarData: BarAreaData(
          show: true, // Hiển thị vùng tô màu phía dưới đường
          color: Colors.red.withOpacity(0.1), // Màu đỏ nhạt (độ trong suốt 10%)
        ),
      ),
    ];
  }

  /// Xây dựng chú giải hiển thị màu sắc tương ứng với thu nhập và chi tiêu
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          'Thu nhập',
          Colors.green[400]!,
        ), // Màu xanh cho thu nhập
        const SizedBox(width: 24),
        _buildLegendItem('Chi tiêu', Colors.red[400]!), // Màu đỏ cho chi tiêu
      ],
    );
  }

  /// Xây dựng một mục trong chú giải với nhãn và màu sắc
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  /// Tính giá trị lớn nhất trong dữ liệu để thiết lập giới hạn trục Y
  /// Trả về ít nhất 100 để tránh lỗi khi giá trị bằng 0
  double _getMaxValue() {
    double max = 0;
    for (var data in widget.timeSeriesData) {
      if (data.income > max)
        max = data.income; // Cập nhật max nếu thu nhập lớn hơn
      if (data.expense > max)
        max = data.expense; // Cập nhật max nếu chi tiêu lớn hơn
    }
    // Trả về ít nhất 100 để tránh lỗi khi khoảng cách bằng 0
    return max > 0 ? max : 100;
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
          Icon(Icons.show_chart, size: 64, color: Colors.grey[300]),
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

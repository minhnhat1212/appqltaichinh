import 'package:flutter/material.dart';

/// Widget hiển thị với hiệu ứng fade in
/// Widget con sẽ dần dần xuất hiện với hiệu ứng mờ dần
class FadeInWidget extends StatefulWidget {
  final Widget child; // Widget con cần hiển thị với hiệu ứng fade in
  final Duration duration; // Thời gian animation (mặc định 500ms)
  final Duration delay; // Độ trễ trước khi bắt đầu animation (mặc định 0)

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controller điều khiển animation
  late Animation<double> _animation; // Animation cho opacity (độ trong suốt)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration); // Tạo controller với duration tùy chỉnh

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn); // Tạo animation với đường cong easeIn (tăng tốc dần)

    Future.delayed(widget.delay, () { // Đợi delay trước khi bắt đầu animation
      if (mounted) { // Kiểm tra widget còn tồn tại
        _controller.forward(); // Bắt đầu animation (từ 0 đến 1)
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Giải phóng controller khi widget bị hủy
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child); // Áp dụng fade transition cho widget con
  }
}

/// Widget hiển thị với hiệu ứng slide in từ dưới lên
/// Widget con sẽ trượt vào từ vị trí ban đầu đến vị trí cuối
class SlideInWidget extends StatefulWidget {
  final Widget child; // Widget con cần hiển thị với hiệu ứng slide
  final Duration duration; // Thời gian animation
  final Duration delay; // Độ trễ trước khi bắt đầu
  final Offset begin; // Vị trí bắt đầu (mặc định: Offset(0, 0.5) - từ dưới lên 50%)

  const SlideInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.begin = const Offset(0, 0.5), // X: 0 (không lệch ngang), Y: 0.5 (lệch xuống 50% chiều cao)
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controller điều khiển animation
  late Animation<Offset> _animation; // Animation cho vị trí (Offset)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = Tween<Offset>(
      begin: widget.begin, // Vị trí bắt đầu (từ dưới lên)
      end: Offset.zero, // Vị trí kết thúc (vị trí gốc)
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)); // Đường cong easeOut (giảm tốc dần)

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward(); // Bắt đầu animation
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _animation, child: widget.child); // Áp dụng slide transition
  }
}

/// Widget hiển thị với hiệu ứng scale
/// Widget con sẽ phóng to từ nhỏ đến lớn với hiệu ứng đàn hồi (elastic)
class ScaleInWidget extends StatefulWidget {
  final Widget child; // Widget con cần hiển thị với hiệu ứng scale
  final Duration duration; // Thời gian animation
  final Duration delay; // Độ trễ trước khi bắt đầu

  const ScaleInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<ScaleInWidget> createState() => _ScaleInWidgetState();
}

class _ScaleInWidgetState extends State<ScaleInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controller điều khiển animation
  late Animation<double> _animation; // Animation cho scale (tỉ lệ phóng to/thu nhỏ)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut); // Đường cong elasticOut (hiệu ứng đàn hồi - bounce)

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward(); // Bắt đầu animation (từ 0 đến 1, với elastic effect sẽ có hiệu ứng vượt quá rồi quay lại)
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child); // Áp dụng scale transition (phóng to/thu nhỏ)
  }
}

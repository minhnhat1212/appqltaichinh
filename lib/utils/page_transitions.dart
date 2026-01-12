import 'package:flutter/material.dart'; // Import Flutter Material để sử dụng PageRoute
import '../theme.dart'; // Import AppTheme để lấy animationDuration

/// Fade Page Route - Chuyển trang với hiệu ứng mờ dần
/// Trang mới sẽ từ trong suốt chuyển sang hiển thị đầy đủ
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page; // Trang đích cần chuyển đến
  final Duration duration; // Thời gian animation

  FadePageRoute({
    required this.page,
    this.duration =
        AppTheme.animationDuration, // Mặc định dùng duration từ theme
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             page, // Builder cho trang
         transitionDuration: duration, // Thời gian chuyển trang
         reverseTransitionDuration: duration, // Thời gian quay lại
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: animation,
             child: child,
           ); // Hiệu ứng fade
         },
       );
}

/// Slide Page Route - Chuyển trang với hiệu ứng trượt
/// Mặc định trượt từ phải sang trái
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page; // Trang đích cần chuyển đến
  final Duration duration; // Thời gian animation
  final Offset beginOffset; // Vị trí bắt đầu (mặc định: từ phải)

  SlidePageRoute({
    required this.page,
    this.duration = AppTheme.animationDuration,
    this.beginOffset = const Offset(1.0, 0.0), // Bắt đầu từ phải (x=1.0)
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           var tween = Tween(
             begin: beginOffset, // Vị trí bắt đầu
             end: Offset.zero, // Vị trí kết thúc (0,0)
           ).chain(CurveTween(curve: Curves.easeOutCubic)); // Curve mượt mà
           var offsetAnimation = animation.drive(tween); // Tạo animation

           return SlideTransition(
             position: offsetAnimation,
             child: child,
           ); // Hiệu ứng slide
         },
       );
}

/// Scale Page Route - Chuyển trang với hiệu ứng phóng to
/// Trang mới sẽ từ nhỏ (0.8) phóng to lên kích thước bình thường (1.0)
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page; // Trang đích cần chuyển đến
  final Duration duration; // Thời gian animation

  ScalePageRoute({
    required this.page,
    this.duration = AppTheme.animationDuration,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           var scaleTween =
               Tween<double>(
                 begin: 0.8, // Bắt đầu từ 80% kích thước
                 end: 1.0, // Kết thúc ở 100% kích thước
               ).chain(
                 CurveTween(curve: Curves.easeOutBack),
               ); // Curve có hiệu ứng bounce nhẹ
           var fadeTween = Tween<double>(
             begin: 0.0,
             end: 1.0,
           ); // Fade từ 0 đến 1

           return FadeTransition(
             opacity: animation.drive(fadeTween), // Hiệu ứng fade
             child: ScaleTransition(
               scale: animation.drive(scaleTween), // Hiệu ứng scale
               child: child,
             ),
           );
         },
       );
}

/// Slide and Fade Page Route - Kết hợp hiệu ứng trượt và mờ dần
/// Trang mới sẽ trượt từ dưới lên và từ mờ sang rõ
class SlideAndFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page; // Trang đích cần chuyển đến
  final Duration duration; // Thời gian animation

  SlideAndFadePageRoute({
    required this.page,
    this.duration = AppTheme.animationDuration,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           var offsetTween = Tween(
             begin: const Offset(0.0, 0.1), // Bắt đầu từ dưới lên (y=0.1)
             end: Offset.zero, // Kết thúc ở vị trí bình thường
           ).chain(CurveTween(curve: Curves.easeOut)); // Curve mượt mà

           var fadeTween = Tween<double>(
             begin: 0.0,
             end: 1.0,
           ); // Fade từ 0 đến 1

           return SlideTransition(
             position: animation.drive(offsetTween), // Hiệu ứng slide
             child: FadeTransition(
               opacity: animation.drive(fadeTween), // Hiệu ứng fade
               child: child,
             ),
           );
         },
       );
}

/// Hero Dialog Route - Route cho dialog với hiệu ứng Hero
/// Dùng để tạo hiệu ứng chuyển đổi mượt mà giữa widget và dialog
class HeroDialogRoute<T> extends PageRoute<T> {
  final Widget page; // Dialog cần hiển thị

  HeroDialogRoute({required this.page});

  @override
  bool get barrierDismissible => true; // Cho phép đóng dialog khi tap ra ngoài

  @override
  String? get barrierLabel => 'Dismiss'; // Label cho barrier

  @override
  Color get barrierColor => Colors.black54; // Màu nền mờ phía sau dialog

  @override
  bool get maintainState => true; // Giữ trạng thái khi quay lại

  @override
  Duration get transitionDuration => AppTheme.animationDuration; // Thời gian animation

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return page; // Trả về dialog
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ), // Hiệu ứng fade với curve
      child: child,
    );
  }
}

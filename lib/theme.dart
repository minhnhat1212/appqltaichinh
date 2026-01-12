import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App Theme Configuration
/// Bao gồm colors, typography, và theme data cho toàn bộ app

class AppColors {
  // Primary Colors - Modern vibrant gradient với HSL tuning
  static const Color primary = Color(0xFF0EA5E9); // Sky Blue 500
  static const Color primaryDark = Color(0xFF0284C7); // Sky Blue 600
  static const Color primaryLight = Color(0xFF7DD3FC); // Sky Blue 300
  static const Color primaryAccent = Color(0xFF38BDF8); // Sky Blue 400

  static const Color secondary = Color(0xFF10B981); // Emerald 500
  static const Color secondaryDark = Color(0xFF059669); // Emerald 600
  static const Color secondaryLight = Color(0xFF6EE7B7); // Emerald 300
  static const Color secondaryAccent = Color(0xFF34D399); // Emerald 400

  // Functional Colors - Vibrant but tasteful
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color info = Color(0xFF3B82F6); // Blue 500

  // Income & Expense với màu sắc rõ ràng
  static const Color income = Color(0xFF10B981); // Emerald 500
  static const Color expense = Color(0xFFEF4444); // Red 500

  // Neutral Colors - Modern palette
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBackground = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8); // Slate 400

  // Border & Divider
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFE2E8F0); // Slate 200

  // Gradients - Enhanced với nhiều stops để smooth hơn
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF0EA5E9), // Sky 500
      Color(0xFF0284C7), // Sky 600
      Color(0xFF0369A1), // Sky 700
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [
      Color(0xFF10B981), // Emerald 500
      Color(0xFF059669), // Emerald 600
      Color(0xFF047857), // Emerald 700
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [
      Color(0xFF10B981), // Emerald 500
      Color(0xFF34D399), // Emerald 400
      Color(0xFF6EE7B7), // Emerald 300
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [
      Color(0xFFEF4444), // Red 500
      Color(0xFFF87171), // Red 400
      Color(0xFFFCA5A5), // Red 300
    ],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient mới cho dark theme (future-ready)
  static const LinearGradient darkGradient = LinearGradient(
    colors: [
      Color(0xFF1E293B), // Slate 800
      Color(0xFF0F172A), // Slate 900
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism Gradients với alpha channels tối ưu
  static LinearGradient glassmorphicGradient = LinearGradient(
    colors: [Colors.white.withOpacity(0.20), Colors.white.withOpacity(0.10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassmorphicGradientStrong = LinearGradient(
    colors: [Colors.white.withOpacity(0.30), Colors.white.withOpacity(0.15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shimmer colors
  static const Color shimmerBase = Color(0xFFE2E8F0); // Slate 200
  static const Color shimmerHighlight = Color(0xFFF1F5F9); // Slate 100
}

class AppTextStyles {
  // Display styles - For hero sections
  static TextStyle display = GoogleFonts.inter(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.2,
  );

  // Headings - Improved hierarchy
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.4,
  );

  static TextStyle h4 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body text - Optimized for readability
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Special styles
  static TextStyle button = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.0,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
    height: 1.6,
  );

  // Amount Display - Numbers với Tabular figures
  static TextStyle amountLarge = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle amountMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextStyle amountSmall = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class AppTheme {
  // Border Radius - 8-based scale
  static const double borderRadiusXSmall = 4.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadius = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusXLarge = 24.0;
  static const double borderRadiusXXLarge = 32.0;

  // Spacing - 4-based scale
  static const double spacingXXSmall = 4.0;
  static const double spacingXSmall = 8.0;
  static const double spacingSmall = 12.0;
  static const double spacing = 16.0;
  static const double spacingMedium = 20.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  static const double spacingXXXLarge = 64.0;

  // Animation Durations - Enhanced timing
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Duration animationDurationMedium = Duration(milliseconds: 350);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  static const Duration animationDurationXSlow = Duration(milliseconds: 800);
  static const Duration shimmerDuration = Duration(milliseconds: 1500);

  // Glassmorphism parameters
  static const double glassBlur = 12.0;
  static const double glassBlurStrong = 20.0;
  static const double glassOpacity = 0.2;
  static const double glassOpacityStrong = 0.3;

  // Stagger delays for list animations
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration staggerDelayFast = Duration(milliseconds: 30);

  // Elevation system - Material 3 inspired
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 4.0;
  static const double elevation4 = 6.0;
  static const double elevation5 = 8.0;

  // Shadows - Tiered shadow system
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get shadowXLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // Glow effects (for buttons, cards, etc.)
  static BoxShadow glowEffect(Color color, {double opacity = 0.3}) {
    return BoxShadow(
      color: color.withOpacity(opacity),
      blurRadius: 20,
      offset: const Offset(0, 8),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,

      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
        brightness: Brightness.light,
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),

      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: AppTextStyles.h3.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        color: AppColors.cardBackground,
        margin: const EdgeInsets.symmetric(
          horizontal: spacing,
          vertical: spacingSmall,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing,
          vertical: spacing,
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation2,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing * 2,
            vertical: spacing,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: spacing,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display,
        displayMedium: AppTextStyles.h1,
        displaySmall: AppTextStyles.h2,
        headlineMedium: AppTextStyles.h3,
        headlineSmall: AppTextStyles.h4,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.button,
        labelSmall: AppTextStyles.caption,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

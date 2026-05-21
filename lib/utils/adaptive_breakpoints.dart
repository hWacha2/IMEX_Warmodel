// lib/utils/adaptive_breakpoints.dart
import 'package:flutter/widgets.dart';

/// Простая система брейкпоинтов для адаптивного дизайна
class AdaptiveBreakpoints {
  static const double compact = 1000;
  static const double medium = 1440;


  static AdaptiveMode of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compact) return AdaptiveMode.compact;
    if (width < medium) return AdaptiveMode.medium;
    return AdaptiveMode.ultraWide;
  }

  /// Масштаб с учётом системного textScaler
  static double scale(BuildContext context, {double base = 1.0}) {
    final mode = of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    
    final modeScale = switch (mode) {
      AdaptiveMode.compact => 0.95,
      AdaptiveMode.medium => 1.0,
      AdaptiveMode.wide => 1.05,
      AdaptiveMode.ultraWide => 1.1,
    };
    
    return textScaler.scale(base * modeScale);
  }
}

enum AdaptiveMode { compact, medium, wide, ultraWide }
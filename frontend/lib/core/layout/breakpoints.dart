import 'package:flutter/widgets.dart';

/// Screen-size classes used for responsive layout.
enum ScreenSize {
  /// Phones: bottom navigation, one column.
  compact,

  /// Tablets / small laptops: sidebar, fewer columns.
  medium,

  /// Desktops: sidebar, full layout.
  expanded;

  static ScreenSize of(BuildContext context) => fromWidth(MediaQuery.sizeOf(context).width);

  static ScreenSize fromWidth(double width) {
    if (width < 760) return ScreenSize.compact;
    if (width < 1100) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  bool get isCompact => this == ScreenSize.compact;
}

import 'package:flutter/material.dart';

class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // Base spacing unit (8px)
  static const double base = 8.0;

  // Spacing scale
  static const double xs = base * 0.5;   // 4px
  static const double sm = base;         // 8px
  static const double md = base * 2;     // 16px
  static const double lg = base * 3;     // 24px
  static const double xl = base * 4;     // 32px
  static const double xxl = base * 5;    // 40px
  static const double xxxl = base * 6;   // 48px

  // Specific spacing values
  static const double zero = 0;
  static const double px1 = 1;
  static const double px2 = 2;
  static const double px4 = 4;
  static const double px6 = 6;
  static const double px8 = 8;
  static const double px10 = 10;
  static const double px12 = 12;
  static const double px14 = 14;
  static const double px16 = 16;
  static const double px18 = 18;
  static const double px20 = 20;
  static const double px24 = 24;
  static const double px28 = 28;
  static const double px32 = 32;
  static const double px36 = 36;
  static const double px40 = 40;
  static const double px48 = 48;
  static const double px56 = 56;
  static const double px64 = 64;
  static const double px72 = 72;
  static const double px80 = 80;

  // Component specific spacing
  static const double buttonHeight = 48;
  static const double buttonMinWidth = 64;
  static const double inputHeight = 56;
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 80;
  static const double tabHeight = 48;
  static const double listItemHeight = 72;
  static const double cardPadding = 16;
  static const double dialogPadding = 24;
  static const double screenPadding = 16;
  static const double sectionSpacing = 32;

  // Border radius
  static const double radiusNone = 0;
  static const double radiusXs = 4;
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusCircle = 9999;

  // Icon sizes
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 40;
  static const double iconXxl = 48;

  // Edge insets presets
  static const EdgeInsets paddingZero = EdgeInsets.zero;
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(vertical: xl);

  static const EdgeInsets paddingSymmetricSm = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets paddingSymmetricMd = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets paddingSymmetricLg = EdgeInsets.symmetric(horizontal: xl, vertical: lg);

  // Screen padding
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: screenPadding);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(screenPadding);
  static const EdgeInsets screenPaddingWithTop = EdgeInsets.fromLTRB(screenPadding, lg, screenPadding, screenPadding);

  // Card padding
  static const EdgeInsets cardContentPadding = EdgeInsets.all(cardPadding);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);

  // Dialog padding
  static const EdgeInsets dialogContentPadding = EdgeInsets.all(dialogPadding);
  static const EdgeInsets dialogActionsPadding = EdgeInsets.fromLTRB(dialogPadding, 0, dialogPadding, dialogPadding);

  // Helper methods
  static double responsiveSpacing(BuildContext context, {
    double mobile = md,
    double tablet = lg,
    double desktop = xl,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return mobile;
    if (width < 1200) return tablet;
    return desktop;
  }

  static EdgeInsets responsivePadding(BuildContext context, {
    EdgeInsets mobile = paddingAllMd,
    EdgeInsets tablet = paddingAllLg,
    EdgeInsets desktop = paddingAllXl,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return mobile;
    if (width < 1200) return tablet;
    return desktop;
  }

  static double responsiveScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return screenPadding;
    if (width < 1200) return screenPadding * 1.5;
    return screenPadding * 2;
  }
}
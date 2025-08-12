import 'package:flutter/material.dart';

/// 구름처럼 말랑한 카드
/// - 기본: 보더 없음 + 은은한 그림자
/// - 옵션:
///   - [elevation] 0.0 ~ 1.0 (섀도우 강도)
///   - [showBorder] (필요할 때만 얇은 보더 표시)
///   - [color] 카드 배경색 지정 (예: 히어로 카드에 AppTheme.primaryBlue)
///   - [clip] 자식 클립 (이미지/잉크 리플을 모서리에 맞춰 자르려면 true)
class CloudCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  // 스타일 옵션
  final double elevation;          // 0.0 ~ 1.0 (기본 0.6: 은은)
  final bool showBorder;           // 기본 false
  final double borderWidth;        // 보더 켤 때 두께
  final Color? borderColor;        // 보더 색 (없으면 outlineVariant 기반)
  final Color? color;              // 카드 배경 (없으면 theme.cardColor)
  final bool clip;                 // 모서리 클립 여부 (이미지/리플 깔끔하게)

  const CloudCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 24,
    this.elevation = 0.6,
    this.showBorder = false,
    this.borderWidth = 1,
    this.borderColor,
    this.color,
    this.clip = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = color ?? theme.cardColor;
    final List<BoxShadow> shadows = _softShadows(isDark, elevation);

    final border = showBorder
        ? Border.all(
            color: (borderColor ?? cs.outlineVariant)
                .withValues(alpha: isDark ? 0.22 : 0.4),
            width: borderWidth,
          )
        : null;

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
        border: border,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    // 모서리 안쪽까지 깔끔히 자르고 싶으면 clip=true
    return clip
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: card,
          )
        : card;
  }

  List<BoxShadow> _softShadows(bool isDark, double strength) {
    final s = strength.clamp(0.0, 1.0);
    if (s == 0) return const [];

    if (isDark) {
      // 다크 모드: 그림자 과하지 않게 1레이어
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18 + 0.10 * s),
          blurRadius: 12 + 10 * s,
          spreadRadius: 0.5 * s,
          offset: Offset(0, 8 + 4 * s),
        ),
      ];
    } else {
      // 라이트 모드: 부드러운 2레이어
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06 + 0.04 * s),
          blurRadius: 18 + 6 * s,
          offset: Offset(0, 8 + 2 * s),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02 + 0.02 * s),
          blurRadius: 4 + 2 * s,
          offset: const Offset(0, 1),
        ),
      ];
    }
  }
}

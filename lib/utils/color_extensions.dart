import 'dart:ui';

extension ColorOpacity on Color {
  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}

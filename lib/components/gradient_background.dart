import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../core/common.dart';

class GradientBackground extends PositionComponent with HasPaint, HasVisibility {
  GradientBackground({Vector2? position, Vector2? size, Anchor? anchor}) {
    if (position != null) super.position.setFrom(position);
    super.size.setFrom(size ?? game_size);
    if (anchor != null) super.anchor = anchor;

    paint.shader = Gradient.linear(Offset.zero, Offset(0, height), [
      const Color(0xFF000000),
      const Color(0xFF0000a0),
    ]);
  }

  @override
  render(Canvas canvas) {
    if ((this as OpacityProvider).opacity == 0) return;
    canvas.drawPaint(paint);
  }
}

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Bordered extends PositionComponent with HasPaint, HasVisibility {
  Bordered({
    double width = 2,
    Color color = Colors.white,
  }) {
    paint.color = color;
    paint.strokeWidth = width;
    paint.style = PaintingStyle.stroke;
  }

  @override
  void onMount() {
    super.onMount();
    if (size.isZero()) size.setFrom((parent as PositionComponent).size);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(5)), paint);
  }
}

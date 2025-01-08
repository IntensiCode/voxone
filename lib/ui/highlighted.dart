import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Highlighted extends PositionComponent with HasPaint, HasVisibility {
  Highlighted({
    double blur = 5,
    double width = 2,
    Color color = Colors.white,
  }) {
    paint.color = color;
    paint.strokeWidth = width;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
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
    paint.style = PaintingStyle.fill;
    final c = paint.color;
    paint.color = Color(0x20FFFFFF);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(5)), paint);
    paint.color = c;
    paint.style = PaintingStyle.stroke;
  }
}

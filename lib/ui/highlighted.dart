import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Highlighted extends PositionComponent with HasPaint, HasVisibility {
  Highlighted({
    this.blur = 5,
    this.stroke_width = 2,
    this.anim = true,
    Color color = Colors.white,
  }) {
    paint.color = color;
    paint.strokeWidth = stroke_width;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    paint.style = PaintingStyle.stroke;
  }

  double stroke_width;
  double blur;
  bool anim;

  @override
  void onMount() {
    super.onMount();
    final pc = parent as PositionComponent;
    pc.size.addListener(() => size.setFrom(pc.size));
    size.setFrom((pc).size);
  }

  double _anim_time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (anim) {
      _anim_time = (_anim_time + dt) % 1;
      paint.strokeWidth = stroke_width / 2 + stroke_width / 2 * sin(_anim_time * pi);
    }
  }

  @override
  void render(Canvas canvas) {
    final r = Radius.circular(5);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, r), paint);
    paint.style = PaintingStyle.fill;
    final c = paint.color;
    paint.color = Color(0x20FFFFFF);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, r), paint);
    paint.color = c;
    paint.style = PaintingStyle.stroke;
  }
}

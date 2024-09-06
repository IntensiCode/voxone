import 'dart:ui';

import 'package:flame/components.dart';

import 'bitmap_font.dart';
import 'fonts.dart';

class BitmapText extends PositionComponent with HasPaint, HasVisibility {
  final String text;
  final BitmapFont font;
  final double fontScale;

  BitmapText({
    required this.text,
    required Vector2 position,
    BitmapFont? font,
    double scale = 1,
    Color? tint,
    Anchor anchor = Anchor.topLeft,
  })  : font = font ?? mini_font,
        fontScale = scale {
    if (tint != null) this.tint(tint);
    this.position.setFrom(position);
    this.font.scale = fontScale;
    final w = this.font.lineWidth(text);
    final h = this.font.lineHeight(fontScale);
    final x = anchor.x * w;
    final y = anchor.y * h;
    this.position.x -= x;
    this.position.y -= y;
    size.setValues(w, h);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    font.paint.color = paint.color;
    font.paint.colorFilter = paint.colorFilter;
    font.paint.filterQuality = FilterQuality.none;
    font.paint.isAntiAlias = false;
    font.paint.blendMode = paint.blendMode;
    font.scale = fontScale;
    font.drawString(canvas, 0, 0, text);
  }
}

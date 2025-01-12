import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/bitmap_font.dart';

class BitmapText extends PositionComponent with HasPaint, HasVisibility, Snapshot {
  final String text;
  final BitmapFont font;
  final double fontScale;

  bool default_snapshot;

  BitmapText({
    required this.text,
    required Vector2 position,
    BitmapFont? font,
    double scale = 1,
    Color? tint,
    this.default_snapshot = true,
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
    renderSnapshot = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (default_snapshot) renderSnapshot = opacity == 1;
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

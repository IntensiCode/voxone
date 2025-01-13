import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/bitmap_font.dart';

class BitmapText extends PositionComponent with HasPaint, HasVisibility, Snapshot {
  final _reference = Vector2.zero();

  final BitmapFont font;
  final double fontScale;

  bool default_snapshot;

  String _text;

  String get text => _text;

  BitmapText({
    required String text,
    required Vector2 position,
    BitmapFont? font,
    double scale = 1,
    Color? tint,
    this.default_snapshot = true,
    Anchor anchor = Anchor.topLeft,
  })  : _text = text,
        font = font ?? mini_font,
        fontScale = scale {
    if (tint != null) this.tint(tint);
    _reference.setFrom(position);
    this.position.setFrom(position);
    this.font.scale = fontScale;
    final w = this.font.lineWidth(_text);
    final h = this.font.lineHeight(fontScale);
    final x = anchor.x * w;
    final y = anchor.y * h;
    this.position.x -= x;
    this.position.y -= y;
    size.setValues(w, h);
    renderSnapshot = false;
  }

  void change_text_in_place(String text) {
    _text = text;
    size.x = font.lineWidth(_text);
    clearSnapshot();
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
    font.drawString(canvas, 0, 0, _text);
  }
}

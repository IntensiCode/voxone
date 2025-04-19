import 'dart:ui';

import 'package:flame/components.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/util/bitmap_font.dart';

class BitmapText extends PositionComponent with HasPaint, HasVisibility, Snapshot {
  final _reference = Vector2.zero();

  final BitmapFont font;
  final double fontScale;
  final Anchor _text_anchor;

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
        _text_anchor = anchor,
        font = font ?? mini_font,
        fontScale = scale {
    if (tint != null) this.tint(tint);
    _reference.setFrom(position);
    this.font.scale = fontScale;
    _update_position(text);
  }

  void _update_position(String text) {
    _text = text;

    font.scale = fontScale;
    final w = font.lineWidth(_text);
    final h = font.lineHeight(fontScale);
    size.setValues(w, h);

    final x = _text_anchor.x * w;
    final y = _text_anchor.y * h;
    position.setFrom(_reference);
    position.x -= x;
    position.y -= y;
  }

  set text(String text) => change_text_in_place(text);

  void change_text_in_place(String text) {
    _text = text;
    _update_position(text);
    clearSnapshot();
  }

  @override
  set isVisible(bool it) {
    super.isVisible = it;
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

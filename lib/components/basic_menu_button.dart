import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';

import '../core/common.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/effects.dart';
import '../util/extensions.dart';

class BasicMenuButton extends SpriteComponent with HasVisibility, TapCallbacks {
  final SpriteSheet sheet;
  final BitmapFont font;
  Function on_tap;
  final double font_scale;

  BasicMenuButton(
    String text, {
    required this.sheet,
    required this.font,
    required this.font_scale,
    required this.on_tap,
    bool selected = false,
    Anchor text_anchor = Anchor.center,
  }) {
    this.selected = selected;
    final p = Vector2.copy(size);
    p.x -= 12;
    p.x *= text_anchor.x;
    p.y *= text_anchor.y;
    p.x += 6;
    add(BitmapText(
      text: text,
      position: p,
      font: font,
      scale: font_scale,
      anchor: text_anchor,
    ));
  }

  ComponentEffect? _highlighted;

  set selected(bool value) {
    if (value) {
      _highlighted ??= added(HighlightEffect());
      sprite = sheet.getSprite(0, 1);
    } else {
      tint(transparent);
      _highlighted?.removeFromParent();
      _highlighted = null;
      sprite = sheet.getSprite(0, 0);
    }
  }

  BitmapText? _checked;

  set checked(bool value) {
    _checked?.removeFromParent();
    final p = Vector2.copy(size);
    p.x -= 6;
    p.y = size.y / 2;
    _checked = added(BitmapText(
      text: value ? 'ON' : 'OFF',
      position: p,
      font: font,
      scale: font_scale,
      anchor: Anchor.centerRight,
    ));
  }

  @override
  void onTapUp(TapUpEvent event) => on_tap();
}

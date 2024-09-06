import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';

import '../util/auto_dispose.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/functions.dart';
import '../util/game_script_functions.dart';
import '../util/nine_patch_image.dart';

class FlowText extends PositionComponent with AutoDispose, GameScriptFunctions, HasVisibility {
  //
  late final List<String> _lines;
  late final int _visible_lines;
  final BitmapFont _font;
  final double _font_scale;
  final Vector2 _insets;
  final bool _background;

  late final double _line_height;
  final List<BitmapText> _showing = [];

  FlowText({
    required String text,
    required BitmapFont font,
    double font_scale = 1,
    Vector2? insets,
    required Vector2 size,
    bool background = false,
    super.position,
    super.anchor,
    super.scale,
  })  : _font = font,
        _font_scale = font_scale,
        _insets = insets ?? Vector2(4, 4),
        _background = background,
        super(size: size) {
    //
    final avail_width = size.x - _insets.x * 2;
    _lines = text.lines().map((it) => _font.reflow(it, avail_width.toInt(), scale: _font_scale)).flattened.toList();

    _line_height = _font.lineHeight(_font_scale) * 1.1;
    // _visible_lines = (size.y - _insets.y * 2 + _line_height / 2) ~/ _line_height;

    var visible_lines = 0;
    var taken_height = _insets.y;
    for (final it in _lines) {
      taken_height += it.isEmpty ? _line_height / 2 : _line_height;
      if (taken_height > size.y) break;
      visible_lines++;
    }
    _visible_lines = max(1, visible_lines);
  }

  @override
  onLoad() async {
    if (_background) add(NinePatchComponent(image: await image('button_plain.png'), size: size));
    _update_shown_lines();
  }

  void _update_shown_lines() {
    _showing.forEach((it) => it.removeFromParent());
    _showing.clear();

    final add_pos = Vector2.copy(_insets);
    final lines = _lines.take(_visible_lines).map((line) {
      final it = BitmapText(text: line, font: _font, anchor: Anchor.topLeft, position: add_pos, scale: _font_scale);
      add_pos.y += line.isEmpty ? _line_height / 2 : _line_height;
      return it;
    });

    _showing.addAll(lines);
    _showing.forEach(add);
  }
}

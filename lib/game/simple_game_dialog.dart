import 'dart:ui';

import 'package:flame/components.dart';

import '../components/flow_text.dart';
import '../components/soft_keys.dart';
import '../core/common.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import '../util/functions.dart';
import '../util/game_script_functions.dart';
import '../util/keys.dart';
import '../util/nine_patch_image.dart';

class SimpleGameDialog extends PositionComponent with AutoDispose, GameScriptFunctions, HasPaint {
  SimpleGameDialog(this._handlers, this._text, this._left, this._right,
      {this.flow_text = false, this.shortcuts = false});

  final Map<GameKey, Function> _handlers;
  final String _text;
  final String? _left;
  final String? _right;
  final bool flow_text;
  final bool shortcuts;

  Keys? keys;

  @override
  onLoad() async {
    super.onLoad();

    if (flow_text) {
      position.setValues(16 + 20, 68 + 16);
      size.setValues(160, 64 - 16);
    } else {
      position.setValues(16 + 20, 68);
      size.setValues(160, 64);
    }

    final bg = await image('button_plain.png');
    fontSelect(tiny_font, scale: 2);
    if (flow_text) {
      const dark = Color(0xC0000000);
      add(RectangleComponent(position: -position, size: game_size, paint: pixel_paint()..color = dark));
      add(FlowText(
        text: _text,
        insets: Vector2(6, 7),
        font: tiny_font,
        position: Vector2.zero(),
        size: size,
        anchor: Anchor.topLeft,
      ));
    } else {
      add(RectangleComponent(position: -position, size: game_size, paint: pixel_paint()..color = shadow));
      add(NinePatchComponent(image: bg, size: size));
      textXY(_text, size.x / 2, size.y / 2, anchor: Anchor.center);
    }

    if (_left != null) {
      await add_button(bg, _left, 0, size.y, Anchor.topLeft, () => _handle(SoftKey.left));
    }
    if (_right != null) {
      await add_button(bg, _right, size.x, size.y, Anchor.topRight, () => _handle(SoftKey.right));
    }

    for (final it in children) {
      if (it is RectangleComponent) continue;
      it.fadeInDeep();
    }

    if (shortcuts) add(keys = Keys());
  }

  _handle(SoftKey it) {
    if (it == SoftKey.left) _handlers[GameKey.soft1]!();
    if (it == SoftKey.right) _handlers[GameKey.soft2]!();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (keys?.check_and_consume(GameKey.soft1) == true) _handlers[GameKey.soft1]!();
    if (keys?.check_and_consume(GameKey.soft2) == true) _handlers[GameKey.soft2]!();
    if (keys?.check_and_consume(GameKey.fire1) == true) _handlers[GameKey.soft2]!();
  }
}

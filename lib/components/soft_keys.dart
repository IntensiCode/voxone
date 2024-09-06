import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import '../core/common.dart';
import '../util/auto_dispose.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import '../util/game_keys.dart';
import '../util/game_script_functions.dart';
import '../util/nine_patch_image.dart';

extension GameScriptFunctionsExtension on GameScriptFunctions {
  Future<SoftKeys> softkeys(
    String? left,
    String? right,
    Function(SoftKey) onTap, {
    BitmapFont? font,
    double font_scale = 2,
    bool at_top = false,
    bool insets = true,
    bool shortcuts = true,
  }) async =>
      added(await SoftKeys.soft(
        left: left,
        right: right,
        font: font,
        font_scale: font_scale,
        onTap: onTap,
        at_top: at_top,
        insets: insets,
        shortcuts: shortcuts,
      ));

  Future<SoftKeys> softkeys_plain(
    String? left,
    String? right,
    Function(SoftKey) onTap, {
    BitmapFont? font,
    double font_scale = 2,
    bool at_top = false,
    bool insets = false,
    bool shortcuts = true,
  }) async =>
      added(await SoftKeys.plain(
        left: left,
        right: right,
        onTap: onTap,
      ));
}

enum SoftKey {
  left,
  right,
}

class SoftKeys extends PositionComponent with AutoDispose, KeyboardHandler, HasGameKeys {
  static Future<SoftKeys> plain({
    String? left,
    String? right,
    required Function(SoftKey) onTap,
  }) async =>
      SoftKeys(
        image: await images.load('button_plain.png'),
        font: tiny_font,
        left: left,
        right: right,
        on_tap: onTap,
        image_size: false,
      );

  static Future<SoftKeys> soft({
    String? left,
    String? right,
    BitmapFont? font,
    double font_scale = 1,
    required Function(SoftKey) onTap,
    bool at_top = false,
    bool insets = true,
    bool shortcuts = true,
  }) async =>
      SoftKeys(
        image: await images.load('button_soft.png'),
        font: font ?? tiny_font,
        font_scale: font_scale,
        left: left,
        right: right,
        on_tap: onTap,
        image_size: true,
        at_top: at_top,
        insets: insets ? null : Vector2.zero(),
        shortcuts: shortcuts,
      );

  final Function(SoftKey) on_tap;

  SoftKeys({
    Vector2? insets,
    required Image image,
    required BitmapFont font,
    required this.on_tap,
    String? left,
    String? right,
    Vector2? padding,
    double font_scale = 1,
    bool image_size = false,
    bool at_top = false,
    bool shortcuts = true,
  }) {
    insets ??= Vector2(2, 1);
    padding ??= Vector2(2, 1);

    final y = at_top ? 0.0 : game_height - insets.y;

    if (left != null) {
      add(SoftKeyButton(
        position: Vector2(insets.x, y),
        anchor: at_top ? Anchor.topLeft : Anchor.bottomLeft,
        image,
        font,
        font_scale,
        padding,
        () => on_tap(SoftKey.left),
      )..set_label(left, image_size));
    }

    if (right != null) {
      add(SoftKeyButton(
        position: Vector2(game_width - insets.x, y),
        anchor: at_top ? Anchor.topRight : Anchor.bottomRight,
        image,
        font,
        font_scale,
        padding,
        () => on_tap(SoftKey.right),
      )..set_label(right, image_size));
    }

    if (shortcuts) onPressed = _onPressed;
  }

  void _onPressed(GameKey key) {
    if (key == GameKey.soft1) on_tap(SoftKey.left);
    if (key == GameKey.soft2) on_tap(SoftKey.right);
  }
}

class SoftKeyButton extends PositionComponent with TapCallbacks {
  final Image _image;
  final BitmapFont _font;
  final Vector2 _padding;
  final double _font_scale;
  final Function() on_tap;

  SoftKeyButton(this._image, this._font, this._font_scale, this._padding, this.on_tap, {super.position, super.anchor});

  void set_label(String text, bool use_image_size) {
    removeAll(children);

    final size = use_image_size ? null : _font.textSize(text);
    size?.add(_padding);

    // for nine patch, assume corner size 8 for now:
    size?.x = (size.x + 7) ~/ 8 * 8;
    size?.y = (size.y + 6) ~/ 8 * 8;

    final bg = _background(_image, size);
    bg.add(BitmapText(
      text: text,
      position: bg.size / 2,
      font: _font,
      scale: _font_scale,
      anchor: Anchor.center,
    ));

    this.size.setFrom(bg.size);
  }

  PositionComponent _background(Image image, Vector2? size) {
    if (size == null || size == image.size) {
      return added(SpriteComponent(sprite: Sprite(image)));
    } else {
      return added(NinePatchComponent(image: image, size: size));
    }
  }

  @override
  void onTapUp(TapUpEvent event) => on_tap();
}

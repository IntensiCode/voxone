import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/input/keys.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/util/auto_dispose.dart';
import 'package:stardash/util/bitmap_font.dart';
import 'package:stardash/util/bitmap_text.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/game_script_functions.dart';
import 'package:stardash/util/nine_patch_image.dart';

extension GameScriptFunctionsExtension on GameScriptFunctions {
  SoftKeys softkeys(
    String? left,
    String? right,
    Function(SoftKey) onTap, {
    BitmapFont? font,
    double font_scale = 2,
    bool at_top = false,
    bool insets = true,
  }) =>
      added(SoftKeys.soft(
        left: left,
        right: right,
        font: font,
        font_scale: font_scale,
        onTap: onTap,
        at_top: at_top,
        insets: insets,
      ));

  SoftKeys softkeys_plain(
    String? left,
    String? right,
    Function(SoftKey) onTap, {
    BitmapFont? font,
    double font_scale = 2,
    bool at_top = false,
    bool insets = false,
  }) =>
      added(SoftKeys.plain(
        left: left,
        right: right,
        onTap: onTap,
      ));
}

enum SoftKey {
  left,
  right,
}

class SoftKeys extends PositionComponent with AutoDispose {
  static SoftKeys plain({
    String? left,
    String? right,
    required Function(SoftKey) onTap,
  }) =>
      SoftKeys(
        image: atlas.sprite('button_plain.png'),
        font: tiny_font,
        left: left,
        right: right,
        on_tap: onTap,
        image_size: false,
      );

  static SoftKeys soft({
    String? left,
    String? right,
    BitmapFont? font,
    double font_scale = 1,
    required Function(SoftKey) onTap,
    bool at_top = false,
    bool insets = true,
  }) =>
      SoftKeys(
        image: atlas.sprite('button_soft.png'),
        font: font ?? tiny_font,
        font_scale: font_scale,
        left: left,
        right: right,
        on_tap: onTap,
        image_size: true,
        at_top: at_top,
        insets: insets ? null : Vector2.zero(),
      );

  final Function(SoftKey) on_tap;

  SoftKeys({
    Vector2? insets,
    required Sprite image,
    required BitmapFont font,
    required this.on_tap,
    String? left,
    String? right,
    Vector2? padding,
    double font_scale = 1,
    bool image_size = false,
    bool at_top = false,
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
  }

  Keys? _keys;
  GameKey? _left;
  GameKey? _right;

  void withGameKeys(Keys keys, GameKey left, [GameKey? right]) {
    _keys = keys;
    _left = left;
    _right = right;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final k = _keys;
    if (k == null) return;

    final l = _left;
    if (l != null && k.check_and_consume(l)) on_tap(SoftKey.left);

    final r = _right;
    if (r != null && k.check_and_consume(r)) on_tap(SoftKey.right);
  }
}

class SoftKeyButton extends PositionComponent with TapCallbacks {
  final Sprite _image;
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

  PositionComponent _background(Sprite image, Vector2? size) {
    if (size == null || size == image.srcSize) {
      return added(SpriteComponent(sprite: image));
    } else {
      return added(NinePatchComponent(image: image, size: size));
    }
  }

  @override
  void onTapUp(TapUpEvent event) => on_tap();
}

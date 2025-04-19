import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/input/shortcuts.dart';
import 'package:stardash/ui/bordered.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/util/auto_dispose.dart';
import 'package:stardash/util/bitmap_font.dart';
import 'package:stardash/util/nine_patch_image.dart';

BitmapButton button({
  Sprite? bgNinePatch,
  required String text,
  int cornerSize = 8,
  Vector2? position,
  Vector2? size,
  BitmapFont? font,
  Anchor? anchor,
  List<String> shortcuts = const [],
  double fontScale = 1,
  Color? tint,
  required Function() onTap,
}) =>
    BitmapButton(
      bg_nine_patch: bgNinePatch ?? atlas.sprite('button_plain.png'),
      text: text,
      cornerSize: cornerSize,
      position: position,
      size: size,
      font: font,
      anchor: anchor,
      shortcuts: shortcuts,
      font_scale: fontScale,
      tint: tint,
      onTap: onTap,
    );

class BitmapButton extends PositionComponent
    with AutoDispose, HasPaint, HasVisibility, TapCallbacks, HasAutoDisposeShortcuts, Snapshot {
  //
  String _text;

  final NinePatchImage? background;
  final BitmapFont font;
  final double font_scale;
  final int cornerSize;
  final Function() onTap;
  final List<String> shortcuts;
  final Vector2? _fixed_size;
  final Vector2? _ref_position;

  BitmapButton({
    Sprite? bg_nine_patch,
    required String text,
    this.cornerSize = 8,
    super.position,
    super.size,
    super.anchor,
    BitmapFont? font,
    this.shortcuts = const [],
    this.font_scale = 1,
    Color? tint,
    required this.onTap,
  })  : _text = text,
        _ref_position = position,
        _fixed_size = size,
        font = font ?? tiny_font,
        background = bg_nine_patch != null ? NinePatchImage(bg_nine_patch, cornerSize: cornerSize) : null {
    if (tint != null) this.tint(tint);
    if (background == null) add(Bordered());
    _update_xy_wh();
  }

  String get text => _text;

  set text(String text) {
    _text = text;
    _update_xy_wh();
    clearSnapshot();
  }

  void _update_xy_wh() {
    if (_ref_position != null) position.setFrom(_ref_position);
    if (_fixed_size != null) return;

    font.scale = font_scale;
    size = font.textSize(text);
    size.x = (size.x ~/ cornerSize * cornerSize).toDouble() + cornerSize * 2;
    size.y = (size.y ~/ cornerSize * cornerSize).toDouble() + cornerSize * 2;
  }

  @override
  void onMount() {
    super.onMount();
    onKeys(shortcuts, (_) => onTap());
  }

  double? _opacity;

  @override
  void update(double dt) {
    super.update(dt);
    if (_opacity != opacity) clearSnapshot();
    _opacity = _opacity;
  }

  @override
  render(Canvas canvas) {
    background?.draw(canvas, 0, 0, size.x, size.y, paint);

    font.scale = font_scale;
    font.paint.color = paint.color;
    font.paint.colorFilter = paint.colorFilter;
    font.paint.filterQuality = FilterQuality.none;
    font.paint.isAntiAlias = false;
    font.paint.blendMode = paint.blendMode;
    font.scale = font_scale;

    final xOff = (size.x - font.lineWidth(text)) / 2;
    final yOff = (size.y - font.lineHeight(font_scale)) / 2;
    font.drawString(canvas, xOff, yOff, text);
  }

  @override
  void onTapUp(TapUpEvent event) => onTap();
}

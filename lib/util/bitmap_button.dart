import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/bitmap_font.dart';
import 'package:voxone/util/nine_patch_image.dart';

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
  required Function(BitmapButton) onTap,
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
    with AutoDispose, HasPaint, HasVisibility, TapCallbacks, HasAutoDisposeShortcuts {
  //
  final NinePatchImage? background;
  final String text;
  final BitmapFont font;
  final double font_scale;
  final int cornerSize;
  final Function(BitmapButton) onTap;
  final List<String> shortcuts;

  bool snapshot = true;

  BitmapButton({
    Sprite? bg_nine_patch,
    required this.text,
    this.cornerSize = 8,
    Vector2? position,
    Vector2? size,
    BitmapFont? font,
    Anchor? anchor,
    this.shortcuts = const [],
    this.font_scale = 1,
    Color? tint,
    required this.onTap,
  })  : font = font ?? tiny_font,
        background = bg_nine_patch != null ? NinePatchImage(bg_nine_patch, cornerSize: cornerSize) : null {
    if (position != null) this.position.setFrom(position);
    if (tint != null) this.tint(tint);
    if (size == null) {
      this.font.scale = font_scale;
      this.size = this.font.textSize(text);
      this.size.x = (this.size.x ~/ cornerSize * cornerSize).toDouble() + cornerSize * 2;
      this.size.y = (this.size.y ~/ cornerSize * cornerSize).toDouble() + cornerSize * 2;
    } else {
      this.size = size;
    }
    final a = anchor ?? Anchor.center;
    final x = a.x * this.size.x;
    final y = a.y * this.size.y;
    this.position.x -= x;
    this.position.y -= y;
  }

  @override
  void onMount() {
    super.onMount();
    onKeys(shortcuts, () => onTap(this));
  }

  Image? _snapshot;

  @override
  render(Canvas canvas) {
    if (snapshot) {
      if (_snapshot == null) {
        final recorder = PictureRecorder();
        _render(Canvas(recorder), pixel_paint());
        final picture = recorder.endRecording();
        _snapshot = picture.toImageSync(size.x.round(), size.y.round());
        picture.dispose();
      }
      canvas.drawImage(_snapshot!, Offset.zero, paint);
    } else {
      _render(canvas, paint);
    }
  }

  void _render(Canvas canvas, Paint paint) {
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
  void onTapUp(TapUpEvent event) => onTap(this);
}

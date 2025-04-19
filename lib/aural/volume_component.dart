import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:stardash/input/keys.dart';
import 'package:stardash/input/shortcuts.dart';
import 'package:stardash/ui/basic_menu_entry.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/ui/highlighted.dart';
import 'package:stardash/util/auto_dispose.dart';
import 'package:stardash/util/bitmap_text.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/nine_patch_image.dart';

class VolumeComponent extends PositionComponent
    with AutoDispose, HasAutoDisposeShortcuts, HasPaint, DragCallbacks, TapCallbacks, HasVisibility, BasicMenuEntry {
  //
  VolumeComponent({
    Sprite? bg_nine_patch,
    String? label,
    super.position,
    super.size,
    super.anchor,
    required this.key_down,
    required this.key_up,
    required this.change,
    required this.volume,
    this.keys,
  }) {
    if (size.isZero()) {
      size.setValues(128, 32);
    }
    if (bg_nine_patch != null) {
      _background = NinePatchImage(bg_nine_patch);
    }
    add(_highlighted = Highlighted());
    if (label != null) {
      add(BitmapText(
        text: label,
        font: mini_font,
        position: Vector2(5, 4),
      ));
    }
  }

  NinePatchImage? _background;
  late Highlighted _highlighted;

  final String key_down;
  final String key_up;
  final Function(double) change;
  double Function() volume;
  Keys? keys;

  bool _selected = false;

  @override
  set selected(bool it) {
    _selected = it;
    _highlighted.isVisible = it;
  }

  @override
  set checked(bool it) {}

  @override
  void update(double dt) {
    super.update(dt);
    if (!_selected) return;
    if (keys?.check_and_consume(GameKey.left) == true) _change(volume() - 0.1);
    if (keys?.check_and_consume(GameKey.right) == true) _change(volume() + 0.1);
  }

  @override
  void onMount() {
    super.onMount();
    onKey(key_down, () => _change(volume() - 0.1));
    onKey(key_up, () => _change(volume() + 0.1));
  }

  void _change(double target) {
    if (!isVisible) return;

    final clamped = (target.clamp(0.0, 1.0) * 10).roundToDouble() / 10;
    if (clamped == volume()) return;
    change(clamped);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_background != null) {
      _background!.draw(canvas, 0, 0, size.x, size.y, paint);
    }

    final top = 4.0;
    final avail_height = size.y - 4 - top;

    final x_step = (size.x - 8) / 11;
    final y_step = avail_height / 10;

    for (int i = 0; i <= 10; i++) {
      final x = 4 + x_step * i;
      final height = (10 - i) * y_step;

      paint.opacity = 0.1;
      canvas.drawRect(Rect.fromLTRB(x + 1, top, x + x_step - 1, size.y - 4), paint);

      if ((volume() * 10).round() < i) continue;

      paint.opacity = 1;
      if (_selected) paint.maskFilter = MaskFilter.blur(BlurStyle.solid, 10);
      canvas.drawRect(Rect.fromLTRB(x + 1, top + height, x + x_step - 1, size.y - 4), paint);
      paint.maskFilter = null;
    }

    paint.opacity = 1;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _update_from_tap(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _update_from_tap(event.localStartPosition + event.localDelta);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _update_from_tap(event.localPosition);
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _update_from_tap(event.localPosition);
  }

  void _update_from_tap(Vector2 local) {
    final x = local.x.clamp(4, size.x - 4);
    _change(((x - 4) / (size.x - 8) * 11).toInt() / 10);
  }
}

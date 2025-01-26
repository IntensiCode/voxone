import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/player/projectiles/directional_projectile.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/util/mutable.dart';

extension HasContextExtensions on HasContext {
  Shadows get shadows => cache.putIfAbsent('shadows', () => Shadows());
}

class Shadows extends Component with HasContext, HasVisibility {
  @override
  void render(Canvas canvas) {
    final projectiles = stage.children.whereType<DirectionalProjectile>();
    for (final it in projectiles) {
      _offset.dx = it.x + it.fake_height * 0.25;
      _offset.dy = it.y + it.fake_height * 0.5;
      canvas.drawCircle(_offset, it.fake_size ?? 3, _shadow_paint);
    }
  }

  final _offset = MutableOffset(0, 0);
}

final _shadow_paint = pixel_paint()..colorFilter = ColorFilter.mode(shadow, BlendMode.srcIn);
final _src_rect = MutRect(0, 0, 0, 0);
final _dst_rect = MutRect(0, 0, 0, 0);

void render_shadow(Canvas canvas, FakeThreeDee pp, Image image, {Rect? src, Rect? dst}) {
  if (src == null) {
    _src_rect.right = image.width.toDouble();
    _src_rect.bottom = image.height.toDouble();
  }
  if (dst == null) {
    _dst_rect.right = pp.scaledSize.x;
    _dst_rect.bottom = pp.scaledSize.y;
  }
  canvas.save();
  canvas.translate(pp.x, pp.y);
  canvas.translate(pp.fake_height * 0.25, pp.fake_height * 0.5);
  canvas.translate(pp.scaledSize.x * 0.2, pp.scaledSize.y * 0.95);
  canvas.rotate(-pi / 8);
  canvas.skew(0.5, 0);
  canvas.scale(1, -0.5);
  canvas.drawImageRect(image, src ?? _src_rect, dst ?? _dst_rect, _shadow_paint);
  canvas.restore();
}

import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/voxel/voxel_sprite.dart';

class VoxelEntity extends VoxelSprite with FakeThreeDee {
  @override
  onMount() {
    super.onMount();
    if (!skip_frames) force_render = true;
  }

  VoxelShadow create_linked_shadow() {
    final it = VoxelShadow(this);
    removed.then((_) {
      if (it.isRemoved || it.isRemoving) return;
      it.removeFromParent();
    });
    return it;
  }

  void render_shadow(Canvas canvas) {
    try {
      final last = last_rendered;
      if (last == null || isRemoving || isRemoved || !isVisible) return;

      final pp = this;
      canvas.save();
      canvas.translate(pp.x, pp.y);
      canvas.translate(fake_height * 0.25, fake_height * 0.5);
      canvas.translate(pp.scaledSize.x * 0.2, pp.scaledSize.y * 0.95);
      canvas.rotate(-pi / 8);
      canvas.skew(0.5, 0);
      canvas.scale(1, -0.5);
      canvas.drawImageRect(last, last_src_rect, last_dst_rect, _shadow_paint);
    } catch (e) {
      if (dev) logError('shadow error for $runtimeType - ignored: $e');
    }
  }

  final _shadow_paint = pixel_paint()..colorFilter = ColorFilter.mode(shadow, BlendMode.srcIn);
}

class VoxelShadow extends Component with HasPaint, HasVisibility {
  VoxelShadow(this._source) {
    paint.color = black.withAlpha(128);
  }

  final VoxelEntity _source;

  @override
  void render(Canvas canvas) {
    if (_source.isRemoving || _source.isRemoved || !_source.isVisible) return;
    canvas.save();
    _source.render_shadow(canvas);
    canvas.restore();
  }
}

import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/voxel/voxel_sprite.dart';

class VoxelEntity extends VoxelSprite with FakeThreeDee {
  VoxelShadow create_linked_shadow() {
    final it = VoxelShadow(this);
    removed.then((_) {
      if (it.isRemoved || it.isRemoving) return;
      it.removeFromParent();
    });
    return it;
  }

  void render_shadow(Canvas canvas, VoxelEntity source) {
    try {
      final last = last_rendered;
      if (last == null || isRemoving || isRemoved || !isVisible) return;
      canvas.drawImageRect(last, last_src_rect, last_dst_rect, _shadow_paint);
    } catch (e) {
      if (dev) logError('shadow error for ${source.runtimeType} - ignored: $e');
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

    final fake_height = _source.fake_height;
    if (fake_height == 0) return;

    final pp = _source;
    canvas.save();
    canvas.translate(pp.x, pp.y);
    canvas.translate(fake_height / 4, fake_height);
    canvas.translate(-pp.scaledSize.x / 2, -pp.scaledSize.y / 2);
    canvas.scaleVector(pp.scale);
    _source.render_shadow(canvas, _source);
    canvas.restore();
  }
}

import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/shadows.dart' as shadows;
import 'package:stardash/game/shared/video_mode.dart';
import 'package:stardash/voxel/voxel_sprite.dart';

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
}

class VoxelShadow extends Component with HasPaint, HasVisibility {
  VoxelShadow(this._source) {
    paint.color = black.withAlpha(128);
  }

  final VoxelEntity _source;

  @override
  void render(Canvas canvas) {
    final last = _source.last_rendered;
    if (last == null || _source.isRemoving || _source.isRemoved || !_source.isVisible) return;
    try {
      canvas.save();
      shadows.render_shadow(canvas, _source, last, src: _source.last_src_rect, dst: _source.last_dst_rect);
    } catch (e) {
      if (dev) logError('shadow error for $runtimeType - ignored: $e');
    } finally {
      canvas.restore();
    }
  }
}

import 'package:dart_minilog/dart_minilog.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/voxel/voxel_sprite.dart';

enum VideoMode {
  performance,
  balanced,
  quality,
}

void apply_video_mode() {
  switch (video) {
    case VideoMode.performance:
      VoxelSprite.update_interval = 0.2;
      VoxelSprite.max_renders_per_frame = 6;
      VoxelSprite.rot_steps = 18;
      VoxelSprite.pixel_multiplier = 1;
      break;
    case VideoMode.balanced:
      VoxelSprite.update_interval = 0.1;
      VoxelSprite.max_renders_per_frame = 12;
      VoxelSprite.rot_steps = 36;
      VoxelSprite.pixel_multiplier = 2;
      break;
    case VideoMode.quality:
      VoxelSprite.update_interval = 0.05;
      VoxelSprite.max_renders_per_frame = 24;
      VoxelSprite.rot_steps = 36 * 2;
      VoxelSprite.pixel_multiplier = 4;
      break;
  }
  logInfo('update_interval=${VoxelSprite.update_interval}');
  logInfo('max_renders_per_frame=${VoxelSprite.max_renders_per_frame}');
  logInfo('rot_steps: ${VoxelSprite.rot_steps}');
  logInfo('pixel_multiplier: ${VoxelSprite.pixel_multiplier}');
}

set video(VideoMode value) {
  _video = value;
  _on_video_change.forEach((it) => it(value));
  apply_video_mode();
}

VideoMode get video => _video;

Disposable on_video_change(Function(VideoMode) listener) {
  _on_video_change.add(listener);
  return Disposable.wrap(() => _on_video_change.remove(listener));
}

final _on_video_change = <Function(VideoMode p1)>[];

var _video = VideoMode.balanced;

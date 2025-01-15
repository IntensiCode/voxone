import 'package:dart_minilog/dart_minilog.dart';
import 'package:voxone/util/stacked_sprite.dart';

enum VideoMode {
  performance,
  balanced,
  quality,
}

set video(VideoMode value) {
  _video = value;
  on_video_change?.call(value);

  switch (value) {
    case VideoMode.performance:
      StackedSprite.update_interval = 0.2;
      StackedSprite.max_renders_per_frame = 6;
      StackedSprite.rot_steps = 18;
      break;
    case VideoMode.balanced:
      StackedSprite.update_interval = 0.1;
      StackedSprite.max_renders_per_frame = 12;
      StackedSprite.rot_steps = 24;
      break;
    case VideoMode.quality:
      StackedSprite.update_interval = 0.05;
      StackedSprite.max_renders_per_frame = 24;
      StackedSprite.rot_steps = 30;
      break;
  }
  logInfo('update_interval=${StackedSprite.update_interval}');
  logInfo('max_renders_per_frame=${StackedSprite.max_renders_per_frame}');
  logInfo('rot_steps: ${StackedSprite.rot_steps}');
}

VideoMode get video => _video;

Function(VideoMode)? on_video_change;

var _video = VideoMode.balanced;

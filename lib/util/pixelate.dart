import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/visual.dart';

Image pixelate(int width, int height, void Function(Canvas) draw) {
  final recorder = PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final result = picture.toImageSync(width, height);
  picture.dispose();
  return result;
}

mixin Pixelate on Component {
  @override
  void renderTree(Canvas canvas) {
    if (visual.pixelate_screen) {
      final recorder = PictureRecorder();
      super.renderTree(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(game_width ~/ 1, game_height ~/ 1);
      canvas.drawImage(image, Offset.zero, pixel_paint());
      image.dispose();
      picture.dispose();
    } else {
      super.renderTree(canvas);
    }
  }
}

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/visual.dart';

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

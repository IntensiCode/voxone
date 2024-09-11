import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/uniforms.dart';

enum Uniform {
  scr_width,
  scr_height,
  time,
}

class Space extends Component with HasPaint {
  final _rect = const Rect.fromLTWH(0, 0, game_width, game_height);

  static FragmentShader? _shader;
  static Uniforms? _uniforms;
  static Paint? _paint;

  static double _time = 0;

  @override
  Future<void> onLoad() async {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    if (_shader != null) return;

    _shader = await loadShader('space.frag');

    _uniforms = Uniforms(_shader!, Uniform.values);
    _uniforms!.set(Uniform.scr_width, game_width);
    _uniforms!.set(Uniform.scr_height, game_height);

    _paint = pixel_paint();
    _paint!.shader = _shader;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _uniforms!.set(Uniform.time, _time);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(_rect, _paint!);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(_src.width.toInt(), _src.height.toInt());
    canvas.drawImageRect(image, _src, _dst, paint);
    image.dispose();
    picture.dispose();
  }

  static const _src = Rect.fromLTWH(0, 0, game_width / 2, game_height / 2);
  static const _dst = Rect.fromLTWH(0, 0, game_width, game_height);
}

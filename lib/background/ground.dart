import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/uniforms.dart';

enum Uniform {
  scr_width,
  scr_height,
  scr_x,
  scr_y,
}

Ground? _ground;

Ground get ground {
  _ground?.removeFromParent();
  return _ground ??= Ground._();
}

class Ground extends Component with HasPaint {
  late final FragmentShader _shader;
  late final Uniforms _uniforms;
  late final Paint _paint;

  double _time = 0;
  final _pos = Vector2(160, 120);

  Ground._();

  @override
  Future<void> onLoad() async {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    _shader = await loadShader('ground.frag');
    _uniforms = Uniforms(_shader, Uniform.values);
    _paint = pixel_paint();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _pos.x = _time * 0.13;
    _pos.y = -_time / 4 * 0.21;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final image = pixelate(_buffer.width.toInt(), _buffer.height.toInt(), (it) {
      _uniforms.set(Uniform.scr_width, _buffer.width);
      _uniforms.set(Uniform.scr_height, _buffer.height);
      _uniforms.set(Uniform.scr_x, _pos.x);
      _uniforms.set(Uniform.scr_y, _pos.y);
      _paint.shader = _shader;
      it.drawRect(_buffer, _paint);
    });
    canvas.drawImageRect(image, _buffer, _screen, paint);
    image.dispose();
  }

  late final _buffer = const Rect.fromLTWH(0, 0, game_width / 2, game_height / 2);
  late final _screen = const Rect.fromLTWH(0, 0, game_width, game_height);
}

import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/uniforms.dart';

class Checkerboard extends PositionComponent with HasPaint, AutoDispose {
  late FragmentShader _shader;

  @override
  void onLoad() async {
    _shader = await loadShader('checkerboard.frag');
    _shader.setVec4(0, const Color(0xFF806030));
    _shader.setVec4(4, const Color(0xFFc0a050));
    _shader.setFloat(8, _rect.width);
    _shader.setFloat(9, _rect.height);
    _shader.setFloat(10, 20);
    _shader.setFloat(11, 128);

    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    paint.shader = _shader;
  }

  double _time = 0;

  @override
  render(Canvas canvas) {
    _time -= 10;
    super.render(canvas);
    _shader.setFloat(12, sin(_time / 1024) * 256);
    _shader.setFloat(13, 128);
    _shader.setFloat(14, _time);
    canvas.scale(1, 2);
    canvas.translate(0, -game_height / 2);
    canvas.drawRect(_rect, paint);
  }

  static const _rect = Rect.fromLTWH(0, game_height / 2, game_width, game_height / 2);
}

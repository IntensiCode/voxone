import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/util/pixelate.dart';
import 'package:stardash/util/uniforms.dart';

class AppearingMoon extends RectangleComponent {
  AppearingMoon() : super(anchor: Anchor.topLeft) {
    size.setFrom(game_size);
    priority = -1000;
  }

  late FragmentShader _shader;

  double _anim_time = 0;
  double _time = 0;
  static const grow_time = 5.0;

  bool finish_zoom = false;
  double _finish_time = 0;
  bool _fixed = false;

  void fix_at(double anim_time, double grow_time) {
    _anim_time = anim_time;
    _time = grow_time;
    _fixed = true;
  }

  @override
  onLoad() async {
    super.onLoad();

    _shader = await loadShader('moon.frag');

    paint.color = white;
    paint.shader = _shader;
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_fixed) return;

    _anim_time += dt / 6;
    _time = min(grow_time, _time + dt);

    if (finish_zoom) {
      _finish_time = min(1.0, _finish_time + dt / 4);
      if (_finish_time >= 1.0) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final pixels = 512;
    final img = pixelate(pixels, pixels, (it) {
      _shader.setFloat(0, pixels.toDouble());
      _shader.setFloat(1, pixels.toDouble());
      _shader.setFloat(2, _anim_time);

      paint.shader = _shader;
      it.drawRect(Rect.fromLTWH(0, 0, pixels.toDouble(), pixels.toDouble()), paint);
    });
    paint.shader = null;

    final i = Curves.decelerate.transform(_time / grow_time) * 1024;
    final f = Curves.decelerate.transform(_finish_time) * 4096;
    final s = i + f;
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, pixels.toDouble(), pixels.toDouble()),
      Rect.fromCenter(center: Offset(game_width / 2, game_height / 2), width: s, height: s),
      paint,
    );
    img.dispose();
  }
}

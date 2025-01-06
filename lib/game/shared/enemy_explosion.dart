import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/uniforms.dart';

class EnemyExplosion extends CircleComponent {
  EnemyExplosion() {
    radius = 128;
  }

  static FragmentShader? _explosion;
  static SpriteAnimation? _anim;

  @override
  Future onLoad() async {
    _explosion ??= await loadShader('explosion.frag');
    _explosion!.setFloat(0, width);
    _explosion!.setFloat(1, height);
    _anim ??= animCR('explosion96.png', 12, 1, 0.1);
    paint.color = white;
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    paint.shader = _explosion!;
    return super.onLoad();
  }

  double _time = 0;
  bool _added = false;

  @override
  void update(double dt) {
    _explosion!.setFloat(2, _time / 2);
    _time += dt;
    if (_time >= 1 && !_added) {
      add(SpriteAnimationComponent(animation: _anim!, removeOnFinish: true)..scale.setAll(2.5));
      _added = true;
    }
  }
}

import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/uniforms.dart';

// FIXME pooled - Decals? or custom?

class EnemyExplosion extends CircleComponent {
  static FragmentShader? _explosion;
  static SpriteAnimation? _anim;

  static preload() async {
    logInfo('preload enemy explosion shader');
    _explosion ??= await loadShader('explosion.frag');
    _anim ??= animCR('explosion96.png', 6, 2, stepTime: 0.1);
  }

  @override
  void onMount() {
    super.onMount();

    final ppc = parent as PositionComponent;
    radius = ppc.size.x / 2;
    anchor = Anchor.center;
    position.setFrom(ppc.position);
    position.x += ppc.size.x / 2;
    position.y += ppc.size.y / 2;

    paint.color = white;
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    paint.shader = _explosion!;
  }

  double _time = 0;
  bool _added = false;

  @override
  void update(double dt) {
    _explosion!.setFloat(0, width);
    _explosion!.setFloat(1, height);
    _explosion!.setFloat(2, _time / 2);

    _time += dt;
    if (_time >= 1 && !_added) {
      add(SpriteAnimationComponent(
        animation: _anim!,
        removeOnFinish: true,
        anchor: Anchor.topLeft,
        size: size,
      ));
      _added = true;
    }
    if (_time >= 2) {
      removeFromParent();
    }
  }
}

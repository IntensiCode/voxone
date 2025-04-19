import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/util/component_recycler.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/functions.dart';
import 'package:stardash/util/uniforms.dart';

extension HasContextExtensions on HasContext {
  Explosions get explosions => cache.putIfAbsent('explosions', () => Explosions());
}

class Explosions extends Component with HasContext {
  final _explosions = ComponentRecycler<Explosion>(() => Explosion._())..precreate(128);

  Explosion spawn(PositionComponent origin) => _explosions.acquire()..reset(origin);

  @override
  onLoad() async => await Explosion.preload();
}

class Explosion extends CircleComponent with Recyclable {
  static FragmentShader? _explosion;
  static SpriteAnimation? _anim;

  static preload() async {
    logInfo('preload enemy explosion shader');
    _explosion ??= await loadShader('explosion.frag');
    _anim ??= animCR('explosion96.png', 3, 4, stepTime: 0.1);
  }

  Explosion._();

  void reset(PositionComponent origin) {
    _time = 0;
    _anim_overlay?.removeFromParent();
    _anim_overlay = null;

    radius = origin.size.x / 2;
    anchor = Anchor.center;
    anchor_to_parent(preserve_current: false);

    paint.color = white;
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
    paint.shader = _explosion!;
  }

  double _time = 0;

  SpriteAnimationComponent? _anim_overlay;

  @override
  void update(double dt) {
    _time += dt;
    if (_time >= 1 && _anim_overlay == null) {
      add(_anim_overlay = SpriteAnimationComponent(
        animation: _anim!,
        removeOnFinish: true,
        anchor: Anchor.topLeft,
        size: size,
      ));
    }
    if (_time >= 2) recycle();
  }

  @override
  void render(Canvas canvas) {
    _explosion!.setFloat(0, width);
    _explosion!.setFloat(1, height);
    _explosion!.setFloat(2, _time / 2);
    super.render(canvas);
  }
}

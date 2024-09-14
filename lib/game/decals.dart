import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/game/checkerboard.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

enum Decal {
  mini_explosion,
  mini_smoke,
}

// TODO all these should be pooled... bullets, too, ofc.. and atlas instead... but for now this is just fine...

class _Decal {
  _Decal(this.position);

  final Vector2 position;
  double time = 0;
}

class _MiniExplosion extends _Decal {
  _MiniExplosion(super.position) {
    position.x += rng.nextDoublePM(20);
    position.y += rng.nextDoublePM(20);
  }

  int which = rng.nextInt(8);
}

class Decals extends Component {
  Decals() {
    priority = 10000;
  }

  late final SpriteAnimation _mini_explosion;
  late final SpriteSheet _explosions;

  final _instances = <Decal, List<_Decal>>{};

  void spawn(Decal decal, Vector2 start) {
    final instances = _instances[decal] ??= List.empty(growable: true);
    instances.add(_MiniExplosion(start.clone()));
  }

  @override
  onLoad() async {
    _mini_explosion = await animCR('explosion_small.png', 5, 1);
    _explosions = await sheetI('explosions.png', 7, 8);
  }

  @override
  void update(double dt) {
    final mini_explosions = _instances[Decal.mini_explosion];
    if (mini_explosions != null) {
      for (final it in mini_explosions) {
        it.position.x += 80 * dt;
        it.position.y -= 20 * dt;
        it.time += dt * 2;
      }
      mini_explosions.removeWhere((it) => it.time >= 1);
    }
  }

  @override
  void render(Canvas canvas) {
    final mini_explosions = _instances[Decal.mini_explosion];
    if (mini_explosions != null) {
      for (final it in mini_explosions) {
        final me = it as _MiniExplosion;
        final column = (it.time * _explosions.columns - 1).toInt();
        final f = _explosions.getSprite(me.which, column);
        f.render(canvas, position: it.position, anchor: Anchor.center, size: _mini_explosion_size);
      }
    }
  }

  final _mini_explosion_size = Vector2.all(16);
}

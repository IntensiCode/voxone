import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

late Decals decals;

enum Decal {
  mini_explosion(1.0),
  teleport(0.3),
  ;

  const Decal(this.anim_time);

  final double anim_time;
}

// TODO all these should be pooled... bullets, too, ofc.. and atlas instead... but for now this is just fine...

class DecalObj {
  DecalObj(this.position);

  final Vector2 position;
  double time = 0;

  final velocity = Vector2(0, 0);
}

class _MiniExplosion extends DecalObj {
  _MiniExplosion(super.position) {
    position.x += rng.nextDoublePM(20);
    position.y += rng.nextDoublePM(20);
    velocity.setValues(80, -20);
  }

  int which = rng.nextInt(8);
}

class Decals extends Component {
  Decals() {
    priority = 10000;
  }

  late final SpriteSheet _explosions;
  late final SpriteAnimation _teleport;

  final _instances = <Decal, List<DecalObj>>{};

  DecalObj spawn(Decal decal, Vector2 start) {
    late final DecalObj result;
    final instances = _instances[decal] ??= List.empty(growable: true);
    if (decal == Decal.mini_explosion) {
      instances.add(result = _MiniExplosion(start.clone()));
    } else {
      instances.add(result = DecalObj(start.clone()));
    }
    return result;
  }

  @override
  onLoad() async {
    _explosions = await sheetI('explosions.png', 7, 8);
    _teleport = await animCR('teleport.png', 5, 1);
  }

  @override
  void update(double dt) {
    final mini_explosions = _instances[Decal.mini_explosion];
    if (mini_explosions != null) {
      for (final it in mini_explosions) {
        it.position.x += it.velocity.x * dt;
        it.position.y -= it.velocity.y * dt;
        it.time += dt * 2;
      }
      mini_explosions.removeWhere((it) => it.time >= 1);
    }

    final teleports = _instances[Decal.teleport];
    if (teleports != null) _update_default(Decal.teleport, dt, teleports);
  }

  void _update_default(Decal decal, double dt, List<DecalObj> decals) {
    for (final it in decals) {
      it.position.x += it.velocity.x * dt;
      it.position.y -= it.velocity.y * dt;
      it.time += dt;
    }
    decals.removeWhere((it) => it.time >= decal.anim_time);
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

    final teleports = _instances[Decal.teleport];
    if (teleports != null) _render_default(Decal.teleport, canvas, teleports);
  }

  void _render_default(Decal decal, Canvas canvas, List<DecalObj> decals) {
    for (final it in decals) {
      final column = (it.time * (_teleport.frames.length - 1) / decal.anim_time).toInt();
      final f = _teleport.frames[column];
      f.sprite.render(canvas, position: it.position, anchor: Anchor.center, size: _default_decal_size);
    }
  }

  final _mini_explosion_size = Vector2.all(16);
  final _default_decal_size = Vector2.all(32);
}

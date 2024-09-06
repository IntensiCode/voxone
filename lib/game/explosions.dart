import 'dart:async';

import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/level_object.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';

class Explosions extends Component {
  Explosions(this._sprites32);

  final SpriteSheet _sprites32;

  final _pool = ComponentRecycler(() => Explosion());

  late final SpriteAnimation _vehicle_explosion;
  late final SpriteAnimation _big_explosion;
  late final SpriteAnimation _explosion;
  late final SpriteAnimation _circular_explosion_1;
  late final SpriteAnimation _circular_explosion_2;
  late final SpriteAnimation _circular_explosion_3;

  @override
  FutureOr<void> onLoad() async {
    _vehicle_explosion = _sprites32.createAnimation(row: 10, stepTime: 0.1, loop: false, from: 0, to: 9);
    _big_explosion = _sprites32.createAnimation(row: 11, stepTime: 0.1, loop: false, from: 0, to: 6);
    _explosion = _sprites32.createAnimation(row: 12, stepTime: 0.1, loop: false, from: 0, to: 5);
    _circular_explosion_1 = _sprites32.createAnimation(row: 13, stepTime: 0.1, loop: false, from: 0, to: 6);
    _circular_explosion_2 = _sprites32.createAnimation(row: 14, stepTime: 0.1, loop: false, from: 0, to: 6);
    _circular_explosion_3 = _sprites32.createAnimation(row: 15, stepTime: 0.1, loop: false, from: 0, to: 6);
    return super.onLoad();
  }

  void spawn_vehicle_explosion({LevelObject? origin, Vector2? position}) {
    soundboard.play(Sound.explosion_hollow);
    _explode(position ?? origin!.position, _vehicle_explosion, origin: origin);
  }

  void spawn_big_explosion({LevelObject? origin, Vector2? position}) {
    soundboard.play(Sound.explosion_2);
    _explode(position ?? origin!.position, _big_explosion, origin: origin);
  }

  void spawn_small_explosion({LevelObject? origin, Vector2? position}) {
    soundboard.play(Sound.explosion_1);
    _explode(position ?? origin!.position, _explosion, origin: origin);
  }

  void spawn_round_explosion({LevelObject? origin, Vector2? position}) {
    soundboard.play(Sound.explosion_1);
    final which = [_circular_explosion_1, _circular_explosion_2, _circular_explosion_3].random();
    _explode(position ?? origin!.position, which, origin: origin);
  }

  void _explode(Vector2 position, SpriteAnimation which, {LevelObject? origin}) {
    entities.add(_pool.acquire()..init(position: position, animation: which));
    _affect_area(origin?.position ?? position, origin);
  }

  void _affect_area(Vector2 position, LevelObject? prop) {
    for (final it in entities.destructibles) {
      if (it == prop) continue;
      final distance = it.position.distanceToSquared(position);
      if (distance < 800) {
        it.on_hit(WeaponType.explosion);
      } else if (distance < 1400) {
        it.on_hit(WeaponType.burning);
      }
    }
    for (final it in entities.prisoners) {
      final distance = it.position.distanceToSquared(position);
      if (distance < 800) {
        it.removeFromParent();
        soundboard.play(Sound.prisoner_death);
      }
    }
  }

  void spawn_explosion_for(LevelProp prop) {
    final vehicle = prop.properties['vehicle'] == true;
    final big = prop.hit_width > 16;
    if (vehicle) {
      spawn_vehicle_explosion(origin: prop);
    } else if (big) {
      spawn_big_explosion(origin: prop);
    } else if (prop.is_flammable) {
      spawn_round_explosion(origin: prop);
    } else {
      spawn_small_explosion(origin: prop);
    }
  }
}

class Explosion extends SpriteAnimationComponent with Recyclable {
  init({required Vector2 position, required SpriteAnimation animation, Anchor anchor = Anchor.bottomCenter}) {
    this.position.x = position.x.roundToDouble();
    this.position.y = position.y.roundToDouble();
    this.animation = animation;
    this.anchor = anchor;
    this.priority = position.y.toInt() + 8;

    animationTicker?.onComplete = recycle;
    animationTicker?.reset();
  }
}

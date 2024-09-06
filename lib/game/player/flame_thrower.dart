import 'package:voxone/game/game_configuration.dart';
import 'package:voxone/game/player/base_weapon.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class FlameThrower extends BaseWeapon {
  static FlameThrower make(SpriteSheet sprites) {
    final animation = sprites.createAnimation(row: 22, stepTime: 0.1, from: 30, to: 35, loop: false);
    return FlameThrower._(animation);
  }

  FlameThrower._(SpriteAnimation animation)
      : super(
          WeaponType.flame_thrower,
          animation,
          Sound.flamethrower,
          fire_rate: configuration.flame_thrower_fire_rate,
          spread: configuration.flame_thrower_spread,
          projectile_speed: 150,
        ) {
    weapon_behaviors.removeWhere((it) => it is RandomSpread);
    weapon_behaviors.add(SweepingSpread());
  }
}

class SweepingSpread extends WeaponBehavior {
  double _spread = 0;
  double _spread_dir = 12;
  double _spread_timeout = 0;

  @override
  void update(BaseWeapon weapon, double dt) {
    if (_spread_timeout < 0.5) {
      _spread_timeout += dt;
    } else {
      _spread_timeout = 0;
      _spread = 0;
    }
  }

  @override
  void on_fire(BaseWeapon weapon, double dt) {
    _spread_timeout = 0;
    _spread += _spread_dir * dt;
    if (_spread.abs() >= configuration.flame_thrower_spread) _spread_dir = -_spread_dir;
    weapon.velocity.rotate(_spread);
  }
}

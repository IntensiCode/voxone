import 'package:voxone/game/game_configuration.dart';
import 'package:voxone/game/player/base_weapon.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:flame/sprite.dart';

class AssaultRifle extends BaseWeapon {
  static AssaultRifle make(SpriteSheet sprites) {
    final animation = sprites.createAnimation(row: 17, stepTime: 0.1, from: 42, to: 44);
    return AssaultRifle._(animation);
  }

  AssaultRifle._(SpriteAnimation animation)
      : super(
          WeaponType.assault_rifle,
          animation,
          Sound.shot_assault_rifle_real,
          fire_rate: configuration.assault_rifle_fire_rate,
          spread: configuration.assault_rifle_spread,
        ) {
    ammo = -1;
  }
}

import 'package:voxone/game/game_configuration.dart';
import 'package:voxone/game/player/base_weapon.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:flame/sprite.dart';

class SubMachineGun extends BaseWeapon {
  static SubMachineGun make(SpriteSheet sprites) {
    final animation = sprites.createAnimation(row: 17, stepTime: 0.1, from: 46, to: 48);
    return SubMachineGun._(animation);
  }

  SubMachineGun._(SpriteAnimation animation)
      : super(
          WeaponType.smg,
          animation,
          Sound.shot_smg,
          fire_rate: configuration.smg_fire_rate,
          spread: configuration.smg_spread,
        );
}

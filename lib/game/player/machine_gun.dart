import 'package:voxone/game/game_configuration.dart';
import 'package:voxone/game/player/base_weapon.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:flame/sprite.dart';

class MachineGun extends BaseWeapon {
  static MachineGun make(SpriteSheet sprites) {
    final animation = sprites.createAnimation(row: 17, stepTime: 0.1, from: 46, to: 48);
    return MachineGun._(animation);
  }

  MachineGun._(SpriteAnimation animation)
      : super(
          WeaponType.machine_gun,
          animation,
          Sound.shot_machine_gun_real,
          fire_rate: configuration.machine_gun_fire_rate,
          spread: configuration.machine_gun_spread,
        );
}

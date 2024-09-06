import 'dart:async';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/game_messages.dart';
import 'package:voxone/game/player/assault_rifle.dart';
import 'package:voxone/game/player/base_weapon.dart';
import 'package:voxone/game/player/bazooka.dart';
import 'package:voxone/game/player/flame_thrower.dart';
import 'package:voxone/game/player/machine_gun.dart';
import 'package:voxone/game/player/shotgun.dart';
import 'package:voxone/game/player/sub_machine_gun.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/on_message.dart';
import 'package:voxone/util/shortcuts.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class Weapons extends Component with AutoDispose, GameContext, HasAutoDisposeShortcuts {
  Weapons(this._sprites16);

  final SpriteSheet _sprites16;

  final weapons = <WeaponType, BaseWeapon>{};

  @override
  FutureOr<void> onLoad() {
    if (weapons.isEmpty) {
      weapons[WeaponType.assault_rifle] = added(AssaultRifle.make(_sprites16));
      weapons[WeaponType.bazooka] = added(Bazooka.make(_sprites16));
      weapons[WeaponType.flame_thrower] = added(FlameThrower.make(_sprites16));
      weapons[WeaponType.machine_gun] = added(MachineGun.make(_sprites16));
      weapons[WeaponType.smg] = added(SubMachineGun.make(_sprites16));
      weapons[WeaponType.shotgun] = added(Shotgun.make(_sprites16));
    }
    return super.onLoad();
  }

  @override
  Future onMount() async {
    super.onMount();

    player.active_weapon ??= weapons[WeaponType.assault_rifle];

    onMessage<Collected>((it) => _handle_weapons(it));
    onMessage<EnterRound>((_) => _reset(reset_weapons: false));
    onMessage<WeaponBonus>((it) => _switch_weapon(it.type));
    onMessage<WeaponEmpty>((_) => _switch_weapon(WeaponType.assault_rifle));
    //...

    onKey('1', () => _switch_weapon(WeaponType.assault_rifle));
    onKey('2', () => _switch_weapon(WeaponType.bazooka));
    onKey('3', () => _switch_weapon(WeaponType.flame_thrower));
    onKey('4', () => _switch_weapon(WeaponType.machine_gun));
    onKey('5', () => _switch_weapon(WeaponType.smg));
    onKey('6', () => _switch_weapon(WeaponType.shotgun));
  }

  void _handle_weapons(Collected it) {
    final type = WeaponType.by_name(it.consumable.properties['type']);
    if (type == null || type == WeaponType.grenades) return;
    player.active_weapon = weapons[type];
    player.active_weapon?.ammo += type.pickup_ammo;
  }

  void _reset({bool reset_weapons = false}) {
    if (reset_weapons) {
      for (final it in weapons.values) {
        it.ammo = 0;
      }
    }
  }

  void _switch_weapon(WeaponType type) {
    final weapon = weapons[type];
    if (weapon == null) return;

    if (weapon.ammo == 0 && !dev) {
      soundboard.play(Sound.empty_click);
    } else {
      if (dev) weapon.ammo += 50;
      player.active_weapon = weapon;
      sendMessage(WeaponSwitched(type));
    }
  }
}

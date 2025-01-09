import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:supercharged/supercharged.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/player/acid_blaster.dart';
import 'package:voxone/game/player/cluster_bomb_cannon.dart';
import 'package:voxone/game/player/ion_pulse_gun.dart';
import 'package:voxone/game/player/plasma_emitter.dart';
import 'package:voxone/game/player/swirl_gun.dart';
import 'package:voxone/game/player/triple_plasma_gun.dart';
import 'package:voxone/game/player/yin_yang_gun.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/game_keys.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/shortcuts.dart';

class WeaponSystem extends Component with AutoDispose, HasAutoDisposeShortcuts, HasContext {
  WeaponSystem(this.player);

  late Player player;

  late PrimaryWeapon primary_weapon;
  SecondaryWeapon? secondary_weapon;

  double? get secondary_cooldown {
    if (secondary_weapon != null) {
      var it = secondary_weapon as SecondaryWeapon;
      return it.cooldown / it.cooldown_time;
    } else {
      return null;
    }
  }

  final _primaries = <PrimaryWeapon, bool>{};
  final _secondaries = <SecondaryWeapon, int>{};

  void switch_primary_to(Type type) {
    final weapon = _primaries.keys.firstWhere((it) => it.runtimeType == type);
    _primaries[weapon] = true;

    primary_weapon.removeFromParent();
    primary_weapon = weapon;
    add(primary_weapon);
  }

  void switch_secondary_to(Type type) {
    final weapon = _secondaries.keys.firstWhere((it) => it.runtimeType == type);
    _secondaries[weapon] = (_secondaries[weapon] ?? 0) + (dev ? 10 : 3);

    secondary_weapon?.removeFromParent();
    secondary_weapon = weapon;
    add(secondary_weapon!);
  }

  void on_secondary_cooldown(double dt) {
    // cooldown all secondary weapons:
    for (final it in _secondaries.entries) {
      final weapon = it.key;
      weapon.cooldown = max(0, weapon.cooldown - dt);
    }
  }

  @override
  void onMount() {
    super.onMount();

    _primaries[TriplePlasmaGun(player)] = false;
    _primaries[AcidBlaster(player)] = false;
    _primaries[IonPulseGun(player)] = false;
    _primaries[SwirlGun(player)] = false;
    _primaries[YinYangGun(player)] = false;

    _secondaries[PlasmaEmitter(player, _on_fired)] = 0;
    _secondaries[ClusterBombCannon(player, _on_fired)] = 0;

    player = parent as Player;
    primary_weapon = _primaries.keys.first;
    add(primary_weapon);

    final initial = _secondaries.keys.toList().random(rng);
    switch_secondary_to(initial.runtimeType);

    if (dev) {
      onKey('r', () {
        logInfo('recharge all secondary weapons');
        _secondaries.forEach((key, value) => _secondaries[key] = 10);
        switch_secondary_to(_secondaries.keys.last.runtimeType);
      });
    }
  }

  void _on_fired(SecondaryWeapon weapon) {
    final count = _secondaries[weapon];
    if (count == null) return;
    if (count <= 0) {
      logError('Secondary weapon fired without ammo');
    } else {
      _secondaries[weapon] = count - 1;
      logInfo('Secondary weapon ammo: $count');
      if (count == 1) {
        logInfo('Secondary weapon out of ammo');
        weapon.cooldown = 0;
        _switch_secondary();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (keys.check_and_consume(GameKey.b_button)) _switch_primary();
    if (keys.check_and_consume(GameKey.y_button)) _switch_secondary();
  }

  void _switch_primary() {
    final bank = _primaries.entries.filter((it) => it.value || dev).toList();
    final index = bank.indexWhere((it) => it.key == primary_weapon);
    final next = bank[(index + 1) % bank.length];
    if (next.key == primary_weapon) return;

    switch_primary_to(next.key.runtimeType);
  }

  void _switch_secondary() {
    final bank = _secondaries.entries.filter((it) => it.value > 0).toList();
    if (bank.isEmpty) {
      secondary_weapon?.removeFromParent();
      secondary_weapon = null;
      return;
    }

    final index = bank.indexWhere((it) => it.key == secondary_weapon);
    final next = bank[(index + 1) % bank.length];
    if (next.key == secondary_weapon) return;

    switch_secondary_to(next.key.runtimeType);
  }
}

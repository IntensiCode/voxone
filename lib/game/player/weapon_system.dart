import 'package:flame/components.dart';
import 'package:supercharged/supercharged.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/player/acid_blaster.dart';
import 'package:voxone/game/player/ion_pulse_gun.dart';
import 'package:voxone/game/player/plasma_gun.dart';
import 'package:voxone/game/player/swirl_gun.dart';
import 'package:voxone/game/player/triple_plasma_gun.dart';
import 'package:voxone/game/player/yin_yang_gun.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/game_keys.dart';
import 'package:voxone/util/shortcuts.dart';

class WeaponSystem extends Component with AutoDispose, HasAutoDisposeShortcuts, HasContext {
  WeaponSystem(this.player);

  late Player player;

  late Component primary_weapon;
  Component? secondary_weapon;

  double secondary_cooldown = 1;

  final _primaries = <Component, bool>{};

  void switch_primary_to(Type type) {
    final weapon = _primaries.keys.firstWhere((it) => it.runtimeType == type);
    _primaries[weapon] = true;

    primary_weapon.removeFromParent();
    primary_weapon = weapon;
    add(primary_weapon);
  }

  @override
  void onMount() {
    super.onMount();

    _primaries[PlasmaGun(player)] = false;
    _primaries[TriplePlasmaGun(player)] = false;
    _primaries[AcidBlaster(player)] = false;
    _primaries[IonPulseGun(player)] = false;
    _primaries[SwirlGun(player)] = false;
    _primaries[YinYangGun(player)] = false;

    player = parent as Player;
    primary_weapon = _primaries.keys.first;
    add(primary_weapon);

    if (dev) {
      primary_weapon.removeFromParent();
      primary_weapon = _primaries.keys.last;
      add(primary_weapon);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (keys.check_and_consume(GameKey.b_button)) {
      _switch_primary();
    }
    if (keys.check_and_consume(GameKey.y_button)) {
      // _switch_secondary();
    }
  }

  void _switch_primary() {
    _primaries[primary_weapon] = true;

    final bank = _primaries.entries.filter((it) => it.value || dev).toList();
    final index = bank.indexWhere((it) => it.key == primary_weapon);
    final next = bank[(index + 1) % bank.length];
    if (next.key == primary_weapon) return;

    primary_weapon.removeFromParent();
    primary_weapon = next.key;
    add(primary_weapon);
  }
}

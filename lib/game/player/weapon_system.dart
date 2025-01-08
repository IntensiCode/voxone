import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/player/plasma_gun.dart';
import 'package:voxone/game/player/triple_plasma_gun.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/game_keys.dart';

class WeaponSystem extends Component with HasContext {
  WeaponSystem(this.player);

  late Player player;

  late Component primary_weapon;
  Component? secondary_weapon;

  double secondary_cooldown = 1;

  final _primaries = <Component, int>{};

  @override
  void onMount() {
    super.onMount();

    _primaries[PlasmaGun(player)] = -1;
    _primaries[TriplePlasmaGun(player)] = -1;

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
    final bank = _primaries.entries.toList();
    logInfo("Switch primary weapon: $bank");
    final index = bank.indexWhere((it) => it.key == primary_weapon);
    logInfo("Current primary weapon: $index");
    final next = bank[(index + 1) % bank.length];
    if (next.key == primary_weapon) {
      logInfo("No other primary weapon available");
      return;
    }

    primary_weapon.removeFromParent();
    primary_weapon = next.key;
    add(primary_weapon);
  }
}

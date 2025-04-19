import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/enemy_wave.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/messages.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/game/stage1/asteroid_wave.dart';
import 'package:stardash/game/stage1/capital_ship_wave.dart';
import 'package:stardash/game/stage1/marauder_wave.dart';
import 'package:stardash/game/stage1/marauder_wave_with_captain.dart';
import 'package:stardash/game/stage1/minefield_wave.dart';
import 'package:stardash/game/stage1/planetary_fleet.dart';
import 'package:stardash/game/stage1/ranger_wave.dart';
import 'package:stardash/input/shortcuts.dart';
import 'package:stardash/util/auto_dispose.dart';
import 'package:stardash/util/extensions.dart';

class EnemiesStage1 extends AutoDisposeComponent with HasAutoDisposeShortcuts, HasContext {
  final List<EnemyWave> _waves = [
    MarauderWave(),
    MarauderWaveWithCaptain(),
    RangerWave(),
    MinefieldWave(),
    PlanetaryFleet(),
    AsteroidsWave(),
    CapitalShipWave(),
  ];

  EnemyWave? _active_wave;

  @override
  void onMount() {
    super.onMount();
    if (dev || cheat) {
      onKey('<Backspace>', () {
        logInfo('skip current wave');
        _active_wave?.defeated = true;
        _active_wave?.removeFromParent();
        stage.children.whereType<Hostile>().forEach((it) => (it as Component).removeFromParent());
      });
    }
  }

  double _clear_time = 0;

  @override
  void update(double dt) {
    if (player.is_dead_or_dying()) {
      return;
    } else if (_active_wave?.defeated == false) {
      final hostiles = stage.children.any((it) => it is Hostile);
      _clear_time = hostiles ? 0 : _clear_time + dt;
      if (_clear_time > 8) {
        logError('Force clear empty wave');
        _clear_time = 0;
        _active_wave?.defeated = true;
        update(0);
      }
      return;
    } else if (_waves.isEmpty) {
      logInfo("All waves defeated");
      removeFromParent();
      sendMessage(EnemiesDefeated());
    } else {
      logInfo("Next wave");
      _active_wave?.removeFromParent();
      _active_wave = added(_waves.removeAt(0));
    }
  }
}

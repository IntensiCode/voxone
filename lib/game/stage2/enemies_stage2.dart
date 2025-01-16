import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/enemy_wave.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage2/recon_wave.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';

class EnemiesStage2 extends AutoDisposeComponent with HasAutoDisposeShortcuts, HasContext {
  final List<EnemyWave> _waves = [
    ReconWave(),
    ReconWave(),
    ReconWave(),
    ReconWave(),
    ReconWave(),
    ReconWave(),
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
      if (_clear_time > 5) {
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

import 'package:dart_minilog/dart_minilog.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder_wave.dart';
import 'package:voxone/game/stage1/marauder_wave_with_captain.dart';
import 'package:voxone/game/stage1/minefield_wave.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/shortcuts.dart';

class EnemiesStage1 extends AutoDisposeComponent with HasAutoDisposeShortcuts, HasContext {
  final List<EnemyWave> _waves = [
    MarauderWave(),
    MarauderWaveWithCaptain(),
    MinefieldWave(),
  ];

  EnemyWave? _active_wave;

  @override
  onLoad() {
    if (dev) {
      onKey('<C-w>', () {
        logInfo("Skip wave");
        _active_wave?.defeated = true;
        _active_wave?.removeFromParent();
        messaging.send(ClearInfoText());
        stage.children.whereType<EnemyHitPoints>().forEach((it) => it.removeFromParent());
      });
    }
  }

  @override
  void update(double dt) {
    if (_active_wave?.defeated == false) {
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

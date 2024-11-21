import 'package:voxone/core/common.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder_wave.dart';
import 'package:voxone/game/stage1/minefield_wave.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/shortcuts.dart';

class EnemiesStage1 extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  final _waves = [MarauderWave(), MinefieldWave()];

  EnemyWave? _active_wave;

  @override
  onLoad() {
    if (dev) {
      onKey('<C-w>', () => _active_wave?.removeFromParent());
    }
  }

  @override
  void update(double dt) {
    if (_active_wave?.defeated == false) {
      return;
    } else if (_waves.isEmpty) {
      removeFromParent();
      sendMessage(EnemiesDefeated());
    } else {
      _active_wave?.removeFromParent();
      _active_wave = added(_waves.removeAt(0));
    }
  }
}

import 'package:flame/components.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder_wave.dart';
import 'package:voxone/game/stage1/minefield_wave.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';

class EnemiesStage1 extends Component {
  final _waves = [MarauderWave(), MinefieldWave()];

  EnemyWave? _active_wave;

  @override
  void update(double dt) {
    if (_active_wave?.defeated == false) {
      return;
    } else if (_waves.isEmpty) {
      removeFromParent();
      sendMessage(EnemiesDefeated());
    } else {
      _active_wave = added(_waves.removeAt(0));
    }
  }
}

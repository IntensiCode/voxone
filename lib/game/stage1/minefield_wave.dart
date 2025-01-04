import 'package:flame/components.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/random.dart';

class MinefieldWave extends Component with EnemyWave, HasContext {
  static const enemies_in_wave = 64;

  MinefieldWave() {
    delay = 3;
  }

  bool _info_shown = false;
  bool _active = false;
  double _next_time = 0;

  @override
  void update(double dt) {
    if (delay > 0) {
      delay -= dt;
      return;
    }
    if (!_info_shown) {
      sendMessage(ShowInfoText(text: 'Approaching Minefield', when_done: () => _active = true));
      _info_shown = true;
      _active = true;
    }
    if (!_active) {
      return;
    }
    if (_wave.length >= enemies_in_wave) {
      defeated = _wave.every((it) => it.isRemoved);
      return;
    }
    if (_next_time > 0) {
      _next_time -= dt;
      return;
    }
    _next_time = 0.2;

    final it = mines.spawn(Vector2(850, -150 + rng.nextDoubleLimit(500)));
    it.then((it) => _wave.add(it));
  }

  final _wave = List<MarauderMine>.empty(growable: true);
}

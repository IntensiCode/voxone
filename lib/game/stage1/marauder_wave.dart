import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/game/context.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/util/messaging.dart';

class MarauderWave extends Component with EnemyWave {
  static const enemies_in_wave = 8;

  MarauderWave() {
    Marauder.can_sweep = true;
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
      sendMessage(ShowInfoText(text: 'Enemy Wave Incoming', when_done: () => _active = true));
      _info_shown = true;
      _active = true;
    }
    if (!_active) {
      return;
    }
    if (_wave.length >= enemies_in_wave) {
      defeated = _wave.every((it) => it.defeated);
      return;
    }
    if (_next_time > 0) {
      _next_time -= dt;
      return;
    }
    _next_time = 0.5;

    final it = Marauder();
    it.target_position.x = 600 + sin(_wave.length * 2 * pi / enemies_in_wave) * 100;
    it.target_position.y = 160 + cos(_wave.length * 2 * pi / enemies_in_wave) * 100;
    _wave.add(it);
    stage.add(it);
  }

  final _wave = List<Marauder>.empty(growable: true);
}

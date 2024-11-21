import 'dart:math';

import 'package:voxone/game/context.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/warping_marauder.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/messaging.dart';

class MarauderWaveWithCaptain extends GameScriptComponent with EnemyWave {
  static const marauders_in_wave = 7;
  static const enemies_in_wave = marauders_in_wave + 1;

  final _wave = List<WarpingMarauder>.empty(growable: true);

  @override
  onLoad() async {
    at(delay, () => sendMessage(ShowInfoText(text: 'Enemy Wave Incoming')));
    at(4.0, _warp_in_marauders);
  }

  _warp_in_marauders() {
    marauders_in_wave.forEach((idx) {
      final it = WarpingMarauder();
      it.target_position.x = 600 + sin(_wave.length * 2 * pi / marauders_in_wave) * 100;
      it.target_position.y = 160 + cos(_wave.length * 2 * pi / marauders_in_wave) * 100;
      _wave.add(it);
      stage.add(it);
    });
  }

  @override
  void update(double dt) {
    if (_wave.length >= enemies_in_wave) {
      defeated = _wave.every((it) => it.defeated);
      return;
    }
  }
}

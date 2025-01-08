import 'dart:math';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/marauder_captain.dart';
import 'package:voxone/game/stage1/warping_marauder.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';

class MarauderWaveWithCaptain extends GameScriptComponent with EnemyWave, HasContext {
  static const marauders_in_wave = 7;
  static const enemies_in_wave = marauders_in_wave + 1;

  final _wave = List<Marauder>.empty(growable: true);

  @override
  void onLoad() {
    can_sweep = true;

    at(delay, () => sendMessage(ShowInfoText(text: 'Enemy Wave Incoming')));

    if (!dev) pause(info_time);

    marauders_in_wave.forEach((idx) {
      at(0.5, () {
        final it = WarpingMarauder();
        it.target_position.x = 600 + sin(_wave.length * 2 * pi / marauders_in_wave) * 100;
        it.target_position.y = 160 + cos(_wave.length * 2 * pi / marauders_in_wave) * 100;
        _wave.add(it);
        stage.add(it);
      });
    });
    at(1.0, () {
      final it = MarauderCaptain();
      it.target_position.x = 600;
      it.target_position.y = 160;
      _wave.add(it);
      stage.add(it);
    });
  }

  @override
  void update(double dt) {
    defeated = _wave.length >= enemies_in_wave && _wave.every((it) => it.defeated);
  }
}

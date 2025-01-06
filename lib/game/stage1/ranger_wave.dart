import 'dart:math';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/warping_ranger.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/messaging.dart';

class RangerWave extends GameScriptComponent with EnemyWave, HasContext {
  static const enemies_in_wave = 24;

  final _wave = List<Marauder>.empty(growable: true);

  @override
  void onLoad() {
    can_sweep = false;

    at(delay, () => sendMessage(ShowInfoText(text: 'Enemy Wave Incoming')));

    if (!dev) pause(info_time);

    enemies_in_wave.forEach((idx) {
      at(0.125, () {
        final it = WarpingRanger();
        it.target_position.x = 600 + sin(_wave.length * 9.1 * pi / enemies_in_wave) * 100;
        it.target_position.y = 160 + cos(_wave.length * 2.3 * pi / enemies_in_wave) * 100;
        _wave.add(it);
        stage.add(it);
      });
    });
  }

  @override
  void update(double dt) {
    defeated = _wave.length >= enemies_in_wave && _wave.every((it) => it.defeated);
  }
}

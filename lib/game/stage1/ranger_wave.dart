import 'dart:math';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/warping_ranger.dart';
import 'package:voxone/game/shared/enemy_wave.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';

class RangerWave extends GameScriptComponent with EnemyWave, HasContext {
  static const enemies_in_wave = 24;

  final _wave = List<Enemy>.empty(growable: true);

  @override
  bool get kill_bonus => killed.length == enemies_in_wave;

  @override
  void onLoad() {
    can_sweep = false;

    after(delay, () => sendMessage(ShowInfoText(text: 'Enemy Wave Incoming')));

    if (!dev) pause_script(info_time);

    enemies_in_wave.forEach((idx) {
      after(0.125, () {
        final it = WarpingRanger(this);
        it.target_position.x = 600 + sin(_wave.length * 9.1 * pi / enemies_in_wave) * 100;
        it.target_position.y = 160 + cos(_wave.length * 2.3 * pi / enemies_in_wave) * 100;
        _wave.add(it);
        stage.add(it);
      });
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    defeated = _wave.length >= enemies_in_wave && _wave.every((it) => it.defeated);
  }
}

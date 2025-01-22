import 'dart:math';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/marauder_captain.dart';
import 'package:voxone/game/enemies/warping_marauder.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/enemy_wave.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';

class MarauderWaveWithCaptain extends GameScriptComponent with EnemyWave, HasContext {
  static final marauders_in_wave = switch (difficulty) {
    Difficulty.easy => 6,
    Difficulty.normal => 7,
    Difficulty.hard => 8,
  };

  static final enemies_in_wave = marauders_in_wave + 1;

  final _wave = List<Enemy>.empty(growable: true);

  @override
  bool get kill_bonus => killed.whereType<WarpingMarauder>().length == marauders_in_wave;

  @override
  void onLoad() {
    can_sweep = true;

    after(delay, () => sendMessage(ShowInfoText(text: 'Enemy Wave Incoming')));

    if (!dev) pause_script(info_time);

    marauders_in_wave.forEach((idx) {
      after(0.5, () {
        final it = WarpingMarauder(this);
        it.target_position.x = 600 + sin(_wave.length * 2 * pi / marauders_in_wave) * 100;
        it.target_position.y = 160 + cos(_wave.length * 2 * pi / marauders_in_wave) * 100;
        _wave.add(it);
        stage.add(it);
      });
    });
    after(1.0, () {
      final it = MarauderCaptain(this, homing: true);
      it.target_position.x = 600;
      it.target_position.y = 160;
      _wave.add(it);
      stage.add(it);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    defeated = _wave.length >= enemies_in_wave && _wave.every((it) => it.defeated);
  }
}

import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/sweeping_marauder.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/enemy_wave.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/random.dart';

class MarauderWave extends GameScriptComponent with HasContext, EnemyWave {
  final enemies_in_wave = switch (difficulty) {
    Difficulty.easy => 8,
    Difficulty.normal => 9,
    Difficulty.hard => 10,
  };

  final _wave = List<Enemy>.empty(growable: true);

  @override
  bool get kill_bonus => kill_count == enemies_in_wave;

  @override
  void onLoad() {
    can_sweep = true;

    after(delay, () => sendMessage(ShowInfoText(text: 'Enemy Wave Incoming')));

    if (!dev) pause_script(info_time);

    enemies_in_wave.forEach((idx) {
      after(0.5, () {
        final it = SweepingMarauder(this);
        it.target_position.x = 600 + sin(_wave.length * 2 * pi / enemies_in_wave) * 100;
        it.target_position.y = 160 + cos(_wave.length * 2 * pi / enemies_in_wave) * 100;
        _wave.add(it);
        stage.add(it);
      });
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    defeated = _wave.length >= enemies_in_wave && _wave.every((it) => it.defeated);

    if (kill_count >= enemies_in_wave / 2 && !_spawned_weapon) {
      logInfo('spawn guaranteed weapon');
      final it = stage.children.whereType<SweepingMarauder>().where((it) => !it.defeated).firstOrNull;
      it?.required_extras = {ExtraId.primaries.random(rng)};
      it?.random_extras_count = 0;
      _spawned_weapon = true;
    }
  }

  bool _spawned_weapon = false;
}

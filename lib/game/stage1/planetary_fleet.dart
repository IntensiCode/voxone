import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/stage1/circling_marauder.dart';
import 'package:voxone/game/stage1/enemy_wave.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/marauder_captain.dart';
import 'package:voxone/game/stage1/passing_ranger.dart';
import 'package:voxone/util/game_script.dart';

class PlanetaryFleet extends GameScriptComponent with EnemyWave, HasContext {
  final _wave = List<Marauder>.empty(growable: true);

  bool _ready = false;
  bool _done_spawning = false;

  @override
  void onLoad() {
    can_sweep = false;

    after(delay, () => sendMessage(ShowInfoText(text: 'Planetary Fleet Incoming')));

    if (!dev) pause(info_time);

    after(0, () => _ready = true);

    for (final pass in _passes) {
      final (start, count, delay, create) = pass;
      final times = List.generate(count, (idx) => start + idx * delay);
      _times.add((times, create));
    }
  }

  final _times = <(List<double>, Function())>[];

  @override
  void update(double dt) {
    super.update(dt);

    defeated = _done_spawning && _wave.every((it) => it.defeated);

    if (!_ready) return;

    _spawn_time += dt;

    for (final (times, create) in _times) {
      if (times.isEmpty) continue;
      if (_spawn_time < times.first) continue;
      times.removeAt(0);

      final it = create();
      _wave.add(it);
      stage.add(it);
    }

    _done_spawning = _times.every((it) => it.$1.isEmpty);
  }

  double _spawn_time = 0.0;

  final _passes = [
    (0, 8, 0.3, () => PassingRanger()),
    (5, 8, 0.3, () => PassingRanger()),
    (15, 8, 0.3, () => CirclingMarauder()..target_position.setValues(1000, 0)),
    (27, 1, 0.0, () => MarauderCaptain()..target_position.setFrom(game_center)),
    (28, 8, 0.3, () => CirclingMarauder()..target_position.setValues(1000, 0)),
  ];
}

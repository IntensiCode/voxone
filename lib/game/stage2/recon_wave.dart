import 'package:supercharged/supercharged.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/enemies/recon_mech.dart';
import 'package:voxone/game/enemies/swirling_recon.dart';
import 'package:voxone/game/shared/enemy_wave.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/game_script.dart';

class ReconWave extends GameScriptComponent with EnemyWave, HasContext {
  final _wave = List<Enemy>.empty(growable: true);

  bool _ready = false;
  bool _done_spawning = false;

  @override
  bool get kill_bonus {
    // if (killed.whereType<PassingRanger>().length == 16) return true;
    // if (killed.whereType<CirclingMarauder>().length == 16) return true;
    return false;
  }

  @override
  Future onLoad() async {
    super.onLoad();

    after(delay, () => sendMessage(ShowInfoText(text: 'Recon Squad Detected')));
    if (!dev) pause_script(info_time);
    after(0, () => _ready = true);
    executeScript();

    for (final pass in _passes) {
      final (start, count, delay, create) = pass;
      final times = List.generate(count, (idx) => start + idx * delay);
      _times.add((times, create));
    }

    await SwirlingRecon.preload();
    await ReconMech.preload();
  }

  final _times = <(List<double>, Function())>[];

  double _clear_time = 0;

  @override
  void update(double dt) {
    super.update(dt);

    final hostiles = stage.children.any((it) => it is Hostile);
    _clear_time = hostiles ? 0 : _clear_time + dt;
    if (_clear_time > 1) {
      var next = _times.map((it) => it.$1.firstOrNull).nonNulls.min();
      if (next != null) next = next - _spawn_time;
      dt = next ?? dt;
      _clear_time = 0;
    }

    defeated = _done_spawning && _wave.every((it) => it.defeated);

    if (_done_spawning || !_ready) return;

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

  late final _passes = [
    // (0, 24, 0.3, () => SwirlingRecon(this)),
    // (0, 1, 0.3, () => ReconMech(this)),
    (0, 16, 0.75, () => ReconMech(this)),
    // (4, 16, 0.3, () => ReconMech(this)),
    // (5, 8, 0.3, () => PassingRanger(this)),
    // (15, 8, 0.3, () => CirclingMarauder(this)..x = 1000),
    // (27, 1, 0.0, () => MarauderCaptain(this)..target_position.setValues(game_center.x + 80, game_center.y - 20)),
    // (28, 8, 0.3, () => CirclingMarauder(this)..x = 1000),
  ];
}

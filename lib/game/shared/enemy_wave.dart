import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/random.dart';

mixin EnemyWave on Component, HasContext {
  double delay = 3;
  double info_time = 1;
  bool defeated = false;

  double _kill_time = 0;

  final _killed = <EnemyEntity>[];
  final _kill_times = <double>[];

  Iterable<EnemyEntity> get killed => _killed;

  Iterable<T> killed_of_type<T>() => _killed.whereType<T>();

  bool get kill_bonus;

  int get kill_count => killed.length;

  int? _streak;
  double? _streak_time;

  int _streak_spawn = 0;

  void got_killed(EnemyEntity enemy) {
    if (dev && killed.contains(enemy)) throw 'no no';
    if (killed.contains(enemy)) return;

    _killed.add(enemy);
    _kill_times.add(_kill_time);

    var streak = 0;
    for (final it in _kill_times) {
      if (_kill_time - it < 0.3) streak++;
    }
    if (streak > 2) {
      logInfo('streak: $streak');
      _streak = streak;
      _streak_time = _kill_time;
    }
  }

  void on_kill_bonus_spawned() {
    _killed.clear();
    _kill_times.clear();
  }

  @override
  void onLoad() => can_sweep = false;

  final _full = {...ExtraId.defaults, ...ExtraId.primaries, ...ExtraId.secondaries};
  final _half = {...ExtraId.defaults, ...ExtraId.primaries};

  @override
  void update(double dt) {
    super.update(dt);
    _kill_time += dt;

    if (_streak_spawn > 0) {
      final where = v2(game_width / 2 + rng.nextDoubleLimit(100), rng.nextDoubleLimit(game_height - 200) + 50);
      final which = switch (_streak_spawn) {
        >= 8 => _full,
        >= 4 => _half,
        _ => ExtraId.defaults,
      };
      extras.spawn(where, player.fake_height, choices: which);
      _streak_spawn--;
    }

    final st = _streak_time;
    if (st == null || _kill_time - st < 0.3) return;

    final s = _streak;
    if (s == null) return;

    logInfo('streak ended: $s');
    _streak_spawn = s - 2;
    for (final it in _kill_times.indexed) {
      if (_kill_time - it.$2 < 0.3) continue;
      _kill_times[it.$1] = -1;
    }
    _streak = null;
    _streak_time = null;
  }
}

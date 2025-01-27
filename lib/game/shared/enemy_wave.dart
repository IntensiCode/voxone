import 'package:flame/components.dart';
import 'package:voxone/game/enemies/enemy.dart';

mixin EnemyWave on Component {
  double delay = 3;
  double info_time = 1;
  bool defeated = false;

  double _kill_time = 0;

  final _killed = <(EnemyEntity, double)>{};

  Iterable<EnemyEntity> get killed => _killed.map((it) => it.$1);

  Iterable<T> killed_of_type<T>() => _killed.map((it) => it.$1).whereType<T>();

  bool get kill_bonus;

  int get kill_count => killed.length;

  void got_killed(EnemyEntity enemy) {
    _killed.add((enemy, _kill_time));
  }

  void on_kill_bonus_spawned() => _killed.clear();

  @override
  void onLoad() => can_sweep = false;

  @override
  void update(double dt) {
    super.update(dt);
    _kill_time += dt;
  }
}

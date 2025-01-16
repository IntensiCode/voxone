import 'package:flame/components.dart';
import 'package:voxone/game/enemies/enemy.dart';

mixin EnemyWave on Component {
  double delay = 3;
  double info_time = 1;
  bool defeated = false;

  final killed = <EnemyEntity>{};

  bool get kill_bonus;
}

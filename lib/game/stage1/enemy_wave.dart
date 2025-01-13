import 'package:flame/components.dart';
import 'package:voxone/game/stage1/marauder.dart';

mixin EnemyWave on Component {
  double delay = 1;
  double info_time = 1;
  bool defeated = false;

  final killed = <MarauderEntity>{};

  bool get kill_bonus;
}

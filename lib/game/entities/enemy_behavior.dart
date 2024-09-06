import 'package:voxone/game/entities/enemy.dart';
import 'package:flame/components.dart';

mixin MovementMode {}

mixin EnemyBehavior on Component {
  void attach(Enemy enemy);

  void offer_reaction() {}
}

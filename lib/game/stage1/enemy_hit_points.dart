import 'package:flame/components.dart';

mixin EnemyHitPoints on Component {
  double hit_points = 10;
  double remaining = 10;

  bool get volatile;

  void on_destroyed();

  void on_hit() {
    if (remaining > 0) remaining--;
    if (remaining == 0) on_destroyed();
  }
}

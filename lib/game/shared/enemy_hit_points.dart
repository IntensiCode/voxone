import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/stacked_sprite.dart';
import 'package:voxone/game/shared/traits.dart';

mixin EnemyHitPoints on Component, HasContext implements Hostile, Target {
  bool mini_explosions_on_hit = true;

  double hit_time = 0;
  double hit_points = 10;
  double remaining = 10;

  @override
  bool get susceptible;

  NotifyingVector2 get position;

  set highlight_mode(HighlightMode mode);

  void reset_hit_points_to(double hp) {
    hit_points = hp;
    remaining = hp;
  }

  void on_destroyed();

  @override
  void on_hit([double damage = 1]) {
    if (remaining > 0) remaining--;
    if (remaining == 0) on_destroyed();
    if (mini_explosions_on_hit) decals.spawn(Decal.mini_explosion, position);
    hit_time += 0.05;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hit_time > 0) hit_time -= dt;
    highlight_mode = hit_time > 0 ? HighlightMode.hit : HighlightMode.none;
  }
}

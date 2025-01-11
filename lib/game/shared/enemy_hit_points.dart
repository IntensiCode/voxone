import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/stacked_sprite.dart';

mixin EnemyHitPoints on Component, HasContext implements Hostile, Integrity, Target {
  bool mini_explosions_on_hit = true;

  double hit_time = 0;
  double hit_points = 10;
  double remaining = 10;

  @override
  double get integrity_in_percent => remaining * 100 / hit_points;

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
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    if (this case HasVisibility it) {
      if (!it.isVisible) return;
    }
    remaining = max(0, remaining - damage);
    if (remaining == 0) on_destroyed();
    final p = intersections?.firstOrNull ?? position;
    if (mini_explosions_on_hit) decals.spawn(Decal.mini_explosion, p);
    hit_time = (hit_time + 0.05).clamp(0.0, 0.5);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hit_time > 0) hit_time = max(0, hit_time - dt);
    highlight_mode = hit_time > 0 ? HighlightMode.hit : HighlightMode.none;
  }
}

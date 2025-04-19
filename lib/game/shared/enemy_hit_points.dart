import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/game/shared/decals.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/voxel/voxel_sprite.dart';

mixin EnemyHitPoints on FakeThreeDee, HasContext implements Hostile, Integrity, Target {
  bool mini_explosions_on_hit = true;

  double hit_time = 0;
  double hit_points = 10;
  double remaining = 10;

  @override
  double get integrity_in_percent => remaining * 100 / hit_points;

  @override
  bool get susceptible;

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
    if (mini_explosions_on_hit && _last_auto_explosion_time <= 0) {
      decals.spawn3d(Decal.mini_explosion, this, pos_override: p);
      _last_auto_explosion_time = 0.05;
    }
    hit_time = (hit_time + 0.05).clamp(0.0, 0.5);
  }

  double _last_auto_explosion_time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (_last_auto_explosion_time > 0) _last_auto_explosion_time -= dt;
    if (hit_time > 0) hit_time = max(0, hit_time - dt);
    highlight_mode = hit_time > 0 ? HighlightMode.hit : HighlightMode.none;
  }
}

import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/stacked_sprite.dart';

class MarauderShot extends PositionComponent with CollisionCallbacks, HasContext, HasPaint, EnemyHitPoints {
  static const _inner = Color(0xFFa0ffa0);
  static const _outer = Color(0xFF209f20);
  static const _core = Color(0xFFffffff);

  MarauderShot() {
    size.setAll(4);
    add(CircleHitbox(radius: 4, anchor: Anchor.center)
      ..renderShape = debug
      ..paint.opacity = 0.2);
    reset_hit_points_to(1);
    mini_explosions_on_hit = false;
  }

  @override
  bool get susceptible => true;

  @override
  set highlight_mode(HighlightMode mode) {}

  @override
  void update(double dt) {
    x -= 300 * dt;
    y += 300 / 4 * dt;
    if (x < -100) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    paint.color = _outer;
    canvas.drawCircle(Offset.zero, 3.5, paint);
    paint.color = _inner;
    canvas.drawCircle(Offset.zero, 3, paint);
    paint.color = _core;
    canvas.drawCircle(Offset.zero, 2, paint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other.hasTrait<Friendly>()) {
      other.onTraits<Target>((it) {
        if (!it.susceptible) return;
        it.on_hit(damage: 1);
        removeFromParent();
      });
    }
  }

  @override
  void on_destroyed() {
    removeFromParent();
    audio.play(Sound.teleport, volume_factor: 0.1);
  }
}

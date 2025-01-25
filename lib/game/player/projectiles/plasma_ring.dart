import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/projectiles/directional_projectile.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';

class PlasmaRing extends PositionComponent
    with CollisionCallbacks, Recyclable, FakeThreeDee, DirectionalProjectile, HasPaint {
  static const _color1 = Color(0xFFa0a0ff);
  static const _color2 = Color(0xFF20209f);

  PlasmaRing() {
    size.setAll(4);
    add(_hitbox = CircleHitbox(radius: 16, anchor: Anchor.center, isSolid: true)..debug());

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 8;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 16);
  }

  @override
  double get base_speed => 32;

  late CircleHitbox _hitbox;

  double _size = 32;
  double _damage = 1;

  void reset(Vector2 origin, double fake_height) {
    _size = 32;
    _damage = switch (difficulty) {
      Difficulty.easy => 1.2,
      Difficulty.normal => 0.9,
      Difficulty.hard => 1.0,
    };
    this.fake_height = fake_height;
    position.setFrom(origin);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _size += 350 * dt + pow(_size, 2) * dt / 100;
    if (_size > 1000) recycle();
    size.setAll(_size);
    _hitbox.radius = _size;
    _damage = (_damage - dt * 2.0).clamp(0.01, 1);
  }

  @override
  void render(Canvas canvas) {
    paint.color = _color2;
    canvas.drawCircle(Offset.zero, _size, paint);
    final mf = paint.maskFilter;
    paint.maskFilter = null;
    paint.color = _color1;
    canvas.drawCircle(Offset.zero, _size, paint);
    paint.maskFilter = mf;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (recycled) return;
    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(intersections: intersectionPoints, damage: _damage * 0.5);
        }
      });
    }
  }
}

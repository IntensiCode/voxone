import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/random.dart';

class RangerLaser extends Component with HasContext, HasPaint {
  RangerLaser(this._source, {Vector2? offset, int? priority, double? damage, double? cool_down}) {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    paint.color = Color.fromARGB(255, 255, 250, 150);
    paint.maskFilter = MaskFilter.blur(BlurStyle.solid, 4);
    this.priority = priority ?? -1000;
    if (offset != null) this.offset.setFrom(offset);
    if (damage != null) this.damage = damage;
    if (cool_down != null) this.cool_down = cool_down;
  }

  final Enemy _source;

  double _cool_down = rng.nextDouble();
  double _active_time = 0;
  bool _heard = false;

  final offset = Vector2.zero();
  final _direction = Vector2(-1, 1 / 4).normalized();
  final _result = RaycastResult<ShapeHitbox>();

  double damage = 0.15;
  double cool_down = 1.0;

  void set_laser_direction(Vector2 direction) {
    _direction.setFrom(direction);
    _direction.normalize();
    if (_direction.length2 < 0.1) _direction.setValues(1, 0);
  }

  @override
  void update(double dt) {
    if (_source.state == EnemyState.exploding) removeFromParent();
    if (_source.state == EnemyState.defeated) removeFromParent();
    if (_source.state == EnemyState.left) removeFromParent();

    if (_source.state != EnemyState.active) return;

    if (_active_time > 0) {
      _on_active(dt);
    } else if (_cool_down > 0) {
      _cool_down = max(0, _cool_down - dt);
    } else {
      _on_ready_to_fire();
    }
  }

  void _on_active(double dt) {
    _active_time = max(0, _active_time - dt);

    final result = _update_raycast_result();
    if (result == null) return;

    final target = result.hitbox?.parent;
    target?.onTraits<Target>((it) {
      it.on_hit(damage: damage);
      if (_heard) return;
      _heard = true;
      audio.play(Sound.plasma, volume_factor: 0.1);
    });
  }

  void _on_ready_to_fire() {
    final result = _update_raycast_result();
    if (result == null) return;

    _cool_down += cool_down;
    _active_time = 0.25;
    _heard = false;
  }

  final _tmp = Vector2.zero();

  RaycastResult<ShapeHitbox>? _update_raycast_result() {
    _tmp.setFrom(_source.position);
    _tmp.add(offset);

    final ray = Ray2(origin: _tmp, direction: _direction);
    return collisionDetection.raycast(ray, hitboxFilter: (hitbox) => hitbox.isFriendly(), out: _result);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_source.state != EnemyState.active) return;
    if (_active_time <= 0) return;

    final double dist;
    if (_result.intersectionPoint != null) {
      dist = _result.intersectionPoint!.distanceTo(_tmp);
    } else {
      dist = 5000.0;
    }

    // FIXME does not work properly for CapitalShip - but it looks ok - so keeping it for now
    final s = (_source as PositionComponent).scale;
    _to.dx = _direction.x * dist / s.x;
    _to.dy = _direction.y * dist / s.y;
    _to.dx += offset.x / s.x;
    _to.dy += offset.y / s.y;
    _from.dx = offset.x;
    _from.dy = offset.y;
    paint.strokeWidth = damage / 0.2;
    canvas.drawLine(_from, _to, paint);
  }

  final _from = MutableOffset(0, 0);
  final _to = MutableOffset(0, 0);
}

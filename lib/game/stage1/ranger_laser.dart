import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/random.dart';

class RangerLaser extends Component with HasContext, HasPaint {
  RangerLaser(this._source) {
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
    paint.color = Color.fromARGB(255, 255, 0, 0);
    paint.maskFilter = MaskFilter.blur(BlurStyle.solid, 3);
  }

  late final Marauder _source;

  double _cool_down = rng.nextDouble();
  double _active_time = 0;
  bool _heard = false;

  final _direction = Vector2(-1, 1 / 4).normalized();
  final _result = RaycastResult<ShapeHitbox>();

  @override
  void update(double dt) {
    if (_source.state == MarauderState.exploding) removeFromParent();
    if (_source.state == MarauderState.defeated) removeFromParent();
    if (_source.state == MarauderState.left) removeFromParent();

    if (_source.state != MarauderState.active) return;

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
      it.on_hit(damage: 0.1);
      if (_heard) return;
      _heard = true;
      soundboard.play(Sound.plasma, volume_factor: 0.1);
    });
  }

  void _on_ready_to_fire() {
    final result = _update_raycast_result();
    if (result == null) return;

    _cool_down += 1.0;
    _active_time = 0.25;
    _heard = false;
  }

  RaycastResult<ShapeHitbox>? _update_raycast_result() {
    final ray = Ray2(origin: _source.position, direction: _direction);
    return collisionDetection.raycast(ray, hitboxFilter: (hitbox) => hitbox.isFriendly(), out: _result);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_source.state != MarauderState.active) return;
    if (_active_time <= 0) return;

    final double dist;
    if (_result.intersectionPoint != null) {
      dist = _result.intersectionPoint!.distanceTo(_source.position);
    } else {
      dist = 5000.0;
    }
    _to.dx = _direction.x * dist / (_source as PositionComponent).scale.x;
    _to.dy = _direction.y * dist / (_source as PositionComponent).scale.y;

    canvas.drawLine(_from, _to, paint);
  }

  final _from = MutableOffset(0, 0);
  final _to = MutableOffset(0, 0);
}

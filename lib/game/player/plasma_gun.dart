import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';

class PlasmaGun extends Component with HasContext {
  PlasmaGun(this._player);

  final Player _player;

  double _cool_down = 0;

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.2;

      final it = PlasmaShot();
      it.position.setFrom(_player.position);
      it.x += 25;
      it.y -= 25 / 4;
      stage.add(it);

      soundboard.play(Sound.shot, volume_factor: 0.5);
    }
  }
}

class PlasmaShot extends PositionComponent with CollisionCallbacks, HasPaint {
  static const _blue1 = Color(0xFFa0a0ff);
  static const _blue2 = Color(0xFF20209f);

  double _start_time = 1;

  PlasmaShot() {
    size.setAll(4);
    add(CircleHitbox(radius: 4, anchor: Anchor.center)
      ..renderShape = debug
      ..paint.opacity = 0.2);
  }

  @override
  void update(double dt) {
    if (_start_time > 0) _start_time -= dt;
    x += 500 * dt;
    y -= 500 / 4 * dt;
    if (x > 900) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    paint.color = _blue2;
    canvas.drawCircle(Offset.zero, 3.5 + _start_time * 4, paint);
    paint.color = _blue1;
    canvas.drawCircle(Offset.zero, 3, paint);
    paint.color = white;
    canvas.drawCircle(Offset.zero, 2, paint);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(intersections: intersectionPoints);
          removeFromParent();
        }
      });
    }
  }
}

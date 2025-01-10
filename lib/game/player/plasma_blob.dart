import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage1/marauder_shot.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/random.dart';

class PlasmaBlob extends PositionComponent with CollisionCallbacks, Recyclable, DirectionalProjectile, HasPaint {
  static late Future<FragmentShader> await_shader;
  static FragmentShader? _shader;

  PlasmaBlob(this._emit_plasma_ring) {
    anchor = Anchor.center;
    size.setAll(16);
    add(CircleHitbox(radius: 8, anchor: Anchor.center, position: size / 2)
      ..renderShape = debug
      ..paint.opacity = 0.2);

    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    _shade.filterQuality = FilterQuality.none;
    _shade.isAntiAlias = false;
  }

  final Function(Vector2) _emit_plasma_ring;

  final _shade = Paint();

  @override
  double get base_speed => 200;

  double _anim_time = rng.nextDoubleLimit(10);

  void reset(Vector2 origin) {
    _anim_time = rng.nextDoubleLimit(10);
    _img?.dispose();
    _img = null;
    position.setFrom(origin);
    x += 25;
    y -= 25 / 4;
  }

  @override
  onLoad() => await_shader.then((it) => _shader = it);

  @override
  void update(double dt) {
    super.update(dt);
    _anim_time += dt;
  }

  Image? _img;

  @override
  void render(Canvas canvas) {
    final shader = _shader;
    if (shader == null) return;

    _img?.dispose();
    _img = pixelate(_rect.width.toInt(), _rect.height.toInt(), (it) {
      shader.setFloat(0, _rect.width);
      shader.setFloat(1, _rect.height);
      shader.setFloat(2, _anim_time);
      _shade.shader ??= shader;
      it.drawRect(_rect, _shade);
    });

    _scaled.right = size.x;
    _scaled.bottom = size.y;
    canvas.drawImageRect(_img!, _rect, _scaled, paint);
  }

  final _rect = Rect.fromLTWH(0, 0, 24, 24);
  final _scaled = MutRect.zero();

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is! MarauderShot && other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(damage: 5, intersections: intersectionPoints);
          recycle();
          _emit_plasma_ring(intersectionPoints.first);
        }
      });
    }
  }
}

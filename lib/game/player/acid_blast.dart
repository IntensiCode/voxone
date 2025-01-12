import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/directional_projectile.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/uniforms.dart';

class AcidBlast extends PositionComponent with CollisionCallbacks, Recyclable, DirectionalProjectile, HasPaint {
  static const initial_damage = 6.0;
  static const start_size = 16.0;
  static const size_speed = 64.0;

  static late Future<FragmentShader> await_shader;
  static FragmentShader? _shader;

  static Future<FragmentShader> preload() {
    logInfo('preload acid blast shader');
    return await_shader = loadShader('acid_blast.frag');
  }

  AcidBlast() {
    anchor = Anchor.center;
    size.setAll(start_size);
    add(_hitbox = CircleHitbox(radius: start_size, anchor: Anchor.center)
      ..renderShape = debug
      ..paint.opacity = 0.2);
    angle = -pi / 16;

    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    _shade.filterQuality = FilterQuality.none;
    _shade.isAntiAlias = false;
  }

  final _shade = Paint();

  late CircleHitbox _hitbox;

  @override
  double get base_speed => 400;

  double _anim_time = rng.nextDoubleLimit(10);

  double _damage = initial_damage;

  void reset(Vector2 origin) {
    _anim_time = rng.nextDoubleLimit(10);
    _damage = initial_damage;
    size.setAll(start_size);
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

    size.x += size_speed * dt;
    size.y += size_speed * dt;

    _hitbox.radius = size.x / 8;
    _hitbox.x = size.x / 2;
    _hitbox.y = size.y / 2;
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

  final _rect = Rect.fromLTWH(0, 0, 64, 32);
  final _scaled = MutRect.zero();

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          _damage /= 2;
          it.on_hit(damage: _damage, intersections: intersectionPoints);
          if (_damage < 1) recycle();
          size.scale(0.5);
        }
      });
    }
  }
}

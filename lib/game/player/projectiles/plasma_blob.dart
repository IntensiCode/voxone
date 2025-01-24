import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/enemies/marauder_shot.dart';
import 'package:voxone/game/player/projectiles/directional_projectile.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/uniforms.dart';

class PlasmaBlob extends PositionComponent
    with CollisionCallbacks, Recyclable, FakeThreeDee, DirectionalProjectile, HasPaint {
  static Future<FragmentShader>? await_shader;
  static FragmentShader? _shader;

  static Future<FragmentShader> preload() {
    logInfo('preload plasma blob shader');
    return PlasmaBlob.await_shader ??= loadShader('plasma_blob.frag');
  }

  PlasmaBlob(this._emit_plasma_ring) {
    anchor = Anchor.center;
    size.setAll(16);
    add(CircleHitbox(radius: 8, anchor: Anchor.center, position: size / 2, isSolid: true)..debug());

    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;

    _shade.filterQuality = FilterQuality.none;
    _shade.isAntiAlias = false;
  }

  final Function(Vector2, double) _emit_plasma_ring;

  final _shade = Paint();

  @override
  double get base_speed => 200;

  double _anim_time = rng.nextDoubleLimit(10);

  void reset(FakeThreeDee origin) {
    _anim_time = rng.nextDoubleLimit(10);
    _img?.dispose();
    _img = null;
    init_fake_3d(origin);
    x += 25;
    y -= 25 / 4;
  }

  @override
  onLoad() => await_shader!.then((it) => _shader = it);

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
    if (recycled) return;
    if (other is! MarauderShot && other.hasTrait<Hostile>()) {
      other.onTraits<Target>((it) {
        if (it.susceptible) {
          it.on_hit(damage: 5, intersections: intersectionPoints);
          recycle();
          _emit_plasma_ring(intersectionPoints.first, fake_height);
        }
      });
    }
  }
}

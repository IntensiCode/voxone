import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/voxel_sprite.dart';

class _Halo extends CircleComponent with HasVisibility {
  _Halo() {
    anchor = Anchor.center;
    radius = 12;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    paint.color = yellow;
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;
  }
}

class HomingBomb extends PositionComponent
    with CollisionCallbacks, HasContext, HasPaint, FakeThreeDee, EnemyHitPoints, Recyclable {
  static late SpriteSheet sheet;

  HomingBomb() {
    size.setAll(4);
    add(CircleHitbox(radius: 8, anchor: Anchor.center, isSolid: true)..debug());
    mini_explosions_on_hit = false;

    add(_Halo());

    paint.color = yellow;
    paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
    paint.isAntiAlias = false;
    paint.filterQuality = FilterQuality.none;

    logInfo('timeout: $_timeout');
  }

  void reset(FakeThreeDee origin) {
    init_fake_3d(origin);
    reset_hit_points_to(15);
    _dir.setZero();
    _anim_time = 0;
    _life_time = 0;
    _tick_time = 0;
  }

  final _dir = Vector2.zero();

  double _anim_time = 0;
  double _life_time = 0;
  double _tick_time = 0;

  var _highlight_mode = HighlightMode.none;

  @override
  bool get susceptible => true;

  @override
  set highlight_mode(HighlightMode mode) => _highlight_mode = mode;

  @override
  void onMount() {
    super.onMount();
    _dir.setFrom(player.position - position);
    _dir.normalize();
    _dir.rotate(rng.nextBool() ? -pi / 8 : pi / 8);
    audio.play(Sound.homing, volume_factor: 0.8);
  }

  final _tmp = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);

    _tmp.setFrom(player.position);
    _tmp.sub(position);
    _tmp.normalize();
    _dir.lerp(_tmp, 0.8 * dt);
    _tmp.scale(0.01);
    _dir.add(_tmp);

    x += _dir.x * dt * 200;
    y += _dir.y * dt * 200;
    if (position.is_outside()) recycle();

    _anim_time = (_anim_time + dt * 1.5) % 1;
    angle = _anim_time * 2 * pi;
    scale.setAll(1 + sin(_anim_time * 2 * pi) * 0.25);

    _life_time += dt;
    if (_life_time > _timeout) on_destroyed();

    decals.spawn3d(Decal.smoke, this);

    _tick_time += dt;
    if (_tick_time > 0.4) {
      _tick_time -= 0.4;
      _tick_time += _life_time / 32;
      audio.play(Sound.homing, volume_factor: 0.8);
    }
  }

  final _timeout = switch (difficulty) {
    Difficulty.easy => 3.75,
    Difficulty.normal => 4,
    Difficulty.hard => 4.25,
  };

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 12, paint);
    paint.colorFilter = _highlight_mode.colorFilter;
    sheet.getSpriteById(0).render(canvas, anchor: Anchor.center);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (recycled) return;
    if (other.hasTrait<Friendly>()) {
      other.onTraits<Target>((it) {
        if (!it.susceptible) return;
        final damage = switch (difficulty) {
          Difficulty.easy => 45,
          Difficulty.normal => 50,
          Difficulty.hard => 55,
        };
        it.on_hit(damage: damage * integrity_in_percent);
        on_destroyed();
        audio.play(Sound.trigger, volume_factor: 0.8);
      });
    }
  }

  @override
  void on_destroyed() {
    if (recycled) return;
    recycle();
    decals.spawn3d(Decal.nuke_explosion, this);
    audio.play(Sound.explosion, volume_factor: 0.1);
    16.forEach((_) => decals.spawn3d(Decal.smoke, this));
  }
}

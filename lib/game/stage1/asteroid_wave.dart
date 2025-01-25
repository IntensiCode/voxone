import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/enemy_wave.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/mutable.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/uniforms.dart';
import 'package:voxone/voxel/voxel_sprite.dart';

class AsteroidsWave extends GameScriptComponent with EnemyWave, HasContext {
  static const enemies_in_wave = 64;

  @override
  bool get kill_bonus => false;

  @override
  void onLoad() {
    after(delay, () => sendMessage(ShowInfoText(text: 'Crossing Asteroid Belt')));

    if (!dev) pause_script(info_time);

    final interval = switch (difficulty) {
      Difficulty.easy => 1.0,
      Difficulty.normal => 0.8,
      Difficulty.hard => 0.75,
    };
    final pos = Vector2.zero();
    enemies_in_wave.forEach((idx) {
      after(interval, () {
        pos.x = 850;
        pos.y = -100 + rng.nextDoubleLimit(300);
        asteroids.spawn(pos);
      });
    });
    after(10, () => defeated = true);
  }
}

extension HasContextExtensions on HasContext {
  Asteroids get asteroids => cache.putIfAbsent('asteroids', () => Asteroids());
}

class Asteroids extends Component with HasContext {
  late ComponentRecycler<Asteroid> _asteroids;

  Asteroid spawn(Vector2 position, {double? radius}) =>
      stage.added(_asteroids.acquire()..reset(position, radius: radius));

  @override
  onLoad() {
    loadShader('rock.frag').then((it) {
      _shader = it;
      _uniforms = Uniforms(it, _Uniform.values);
      _shader_paint = pixel_paint()..shader = it;
    });
    _asteroids = ComponentRecycler(() => Asteroid());
  }
}

enum _Uniform {
  scr_width,
  scr_height,
  rot_x,
  rot_y,
  rnd_hash,
}

FragmentShader? _shader;
Uniforms<_Uniform>? _uniforms;
Paint? _shader_paint;

class Asteroid extends PositionComponent
    with CollisionCallbacks, FakeThreeDee, HasContext, HasPaint, EnemyHitPoints, Recyclable {
  //
  Asteroid() {
    size.setAll(32);
    anchor = Anchor.center;
    add(_hitbox = CircleHitbox(radius: 1, anchor: Anchor.center, isSolid: true)..anchor_to_parent());
  }

  late CircleHitbox _hitbox;

  void reset(Vector2 origin, {double? radius}) {
    radius ??= rng.nextDoubleLimit(32) + 16;
    size.setAll(radius * 2);
    _hitbox.size.setAll(radius * 1.2);
    _hitbox.anchor_to_parent(preserve_current: false);

    position.setFrom(origin);
    fake_height = 50;
    hit_time = 0;

    _last?.dispose();
    _last = null;
    _last_collision = null;
    _last_collision_sound = 0;

    reset_hit_points_to(switch (difficulty) {
      Difficulty.easy => 40 + (size.x / 2),
      Difficulty.normal => 55 + (size.x / 2) * 1.5,
      Difficulty.hard => 70 + (size.x / 2) * 2.0,
    });

    _became_visible = false;
    _destroyed = false;
    _dir_override.setZero();
    _dir_override.x = -100 + rng.nextDoubleLimit(50);
    _dir_override.y = 20 + rng.nextDoublePM(10);

    _rnd_hash = rng.nextDoubleLimit(256) + 600;
    _rot_x = 0.2 + rng.nextDoublePM(1);
    if (rng.nextBool()) _rot_x = -_rot_x;
    _rot_y = 0.2 + rng.nextDoubleLimit(1);
    if (rng.nextBool()) _rot_y = -_rot_y;

    _down_sample = switch (video) {
      VideoMode.performance => 2,
      VideoMode.balanced => 2,
      VideoMode.quality => 1,
    };

    _skip_frames = switch (video) {
      VideoMode.performance => 2,
      VideoMode.balanced => 1,
      VideoMode.quality => 0,
    };
  }

  late int _skip_frames;
  late int _down_sample;
  late double _rnd_hash;
  late double _rot_x;
  late double _rot_y;

  final _dir_override = Vector2.zero();
  bool _became_visible = false;
  bool _destroyed = false;
  var _highlight_mode = HighlightMode.none;

  @override
  bool get susceptible => !_destroyed;

  @override
  bool get show_indicator => false;

  @override
  set highlight_mode(HighlightMode mode) => _highlight_mode = mode;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    final full_hit = remaining == hit_points;
    super.on_hit(intersections: intersections, damage: damage);
    _dir_override.x += damage * 150 / size.x;
    if (remaining <= 0 && full_hit) {
      // recycle in on_destroyed
      extras.spawn3d(this, choices: _full_hit);
    } else if (remaining <= 0) {
      // recycle in on_destroyed
      extras.spawn3d(this, choices: ExtraId.primaries);
    } else if (remaining < hit_points / 2 && hit_points > 30) {
      // may recycle if parts are too small
      _split();
    } else {
      // just some smoke
      decals.spawn3d(Decal.smoke, this);
    }
  }

  final _full_hit = <ExtraId>{...ExtraId.defaults, ...ExtraId.secondaries};

  @override
  void on_destroyed() {
    if (_destroyed) return;
    _destroyed = true;
    recycle();
    _multi_smoke();
    _hollow_sound();
  }

  void _hollow_sound() {
    if (position.is_outside()) return;
    if (_last_collision_sound > 0) return;
    _last_collision_sound = 0.2;
    audio.play(Sound.explosion_hollow, volume_factor: 0.25);
  }

  void _split() {
    final other_part = 0.3 + rng.nextDoubleLimit(0.2);
    final loss = rng.nextDoubleLimit(0.1);
    final our_part = 1 - other_part - loss;

    final other_size = size.x / 2 * other_part;
    if (other_size > 16) {
      final other = asteroids.spawn(position, radius: size.x / 2 * other_part);
      other.y += size.y / 3;
      other.reset_hit_points_to(remaining * other_part);
      other._dir_override.x = _dir_override.x + rng.nextDoublePM(10);
      other._dir_override.y = rng.nextDoubleLimit(10);
    }

    final our_size = size.x / 2 * our_part;
    if (our_size > 16) {
      reset(position, radius: size.x / 2 * our_part);
      reset_hit_points_to(remaining * our_part);
      y -= size.y / 3;
      _dir_override.x = _dir_override.x + rng.nextDoublePM(10);
      _dir_override.y = -rng.nextDoubleLimit(10);
    } else {
      recycle();
    }

    _multi_smoke();
    _hollow_sound();
  }

  void _multi_smoke() {
    for (int i = 0; i < 20; i++) {
      decals.spawn3d(Decal.smoke, this, pos_range: size.x / 2);
    }
  }

  double _anim_time = 0;
  final _tmp = Vector2.zero();

  @override
  void update(double dt) {
    alreadyCollided.clear();

    super.update(dt);

    if (_last_collision_sound > 0) _last_collision_sound -= dt;

    _anim_time += dt / 6;

    _tmp.setFrom(_dir_override);
    _tmp.scale(dt);
    position.add(_tmp);

    final outside = position.is_outside(buffer: 200);
    if (!outside) _became_visible = true;
    if (_became_visible && outside) recycle();
  }

  final _ours = Vector2.zero();
  final _theirs = Vector2.zero();

  static final alreadyCollided = <Asteroid>[];

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Asteroid) {
      _collide(other);
    } else if (other.hasTrait<Friendly>()) {
      other.onTraits<Target>((it) {
        if (recycled) return;
        if (!it.susceptible) return;
        _hit_target(it, intersections: intersectionPoints);

        if (hit_points > 30) {
          _split();
        } else {
          recycle();
        }

        _multi_smoke();
        _hollow_sound();
      });
    }
  }

  void _collide(Asteroid other) {
    if (other == _last_collision) return;
    _last_collision = other;

    //
    // lovely work.. as always.. :-D
    //
    if (alreadyCollided.contains(this)) return;
    if (alreadyCollided.contains(other)) return;
    alreadyCollided.add(this);
    alreadyCollided.add(other);

    _ours.setFrom(this._dir_override);
    final os = _ours.normalize();
    _theirs.setFrom(other._dir_override);
    final ts = _theirs.normalize();

    final m1 = size.x;
    final m2 = other.size.x;
    final u1 = _ours;
    final u2 = _theirs;
    final v1 = (u1 * (m1 - m2) + u2 * m2 * 2) / (m1 + m2);
    final v2 = (u2 * (m2 - m1) + u1 * m1 * 2) / (m1 + m2);
    this._dir_override.x = v1.x;
    this._dir_override.y = v1.y;
    other._dir_override.x = v2.x;
    other._dir_override.y = v2.y;

    this._dir_override.scale(ts / 2 + os / 2);
    other._dir_override.scale(os / 2 + ts / 2);

    if (position.is_outside()) return;

    _hollow_sound();
  }

  Asteroid? _last_collision;

  double _last_collision_sound = 0;

  void _hit_target(Target it, {Set<Vector2>? intersections}) {
    final damage = switch (difficulty) {
      Difficulty.easy => remaining,
      Difficulty.normal => remaining * 1.5,
      Difficulty.hard => remaining * 2.0,
    };
    it.on_hit(damage: damage, intersections: intersections);

    position.x -= 10;
    position.y += 10 / 4;
    for (int i = 0; i < 5; i++) {
      final d = decals.spawn3d(Decal.mini_explosion, this);
      d.velocity.setValues(-10.0 * i, 10 / 4 * i);
      d.time = rng.nextDoubleLimit(0.2);
    }
    recycle();

    _hollow_sound();
  }

  @override
  void onRemove() {
    _last?.dispose();
    _last = null;
  }

  int _frame = 0;
  Image? _last;

  @override
  void render(Canvas canvas) {
    if (_shader == null) return;

    _src.right = size.x ~/ _down_sample + 0;
    _src.bottom = size.y ~/ _down_sample + 0;
    _dst.right = size.x;
    _dst.bottom = size.y;

    if (_last != null && _frame++ < _skip_frames) {
      paint.colorFilter = _highlight_mode.colorFilter;
      canvas.drawImageRect(_last!, _src, _dst, paint);
      return;
    }
    _frame = 0;

    _last?.dispose();
    _last = pixelate(_src.right.toInt(), _src.bottom.toInt(), (it) {
      _uniforms?.set(_Uniform.scr_width, _src.right);
      _uniforms?.set(_Uniform.scr_height, _src.bottom);
      _uniforms?.set(_Uniform.rot_x, _anim_time * pi * 2 * _rot_x);
      _uniforms?.set(_Uniform.rot_y, _anim_time * pi * 0.2 * _rot_y);
      _uniforms?.set(_Uniform.rnd_hash, _rnd_hash);
      it.drawRect(_src, _shader_paint!);
    });
    paint.colorFilter = _highlight_mode.colorFilter;
    canvas.drawImageRect(_last!, _src, _dst, paint);
  }

  final _src = MutRect(0, 0, 32, 32);
  final _dst = MutRect(0, 0, 128, 128);
}

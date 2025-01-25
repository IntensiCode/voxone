import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/game/shared/voxel_entity.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';

var rotate_mines = true;

extension HasContextExtensions on HasContext {
  MarauderMines get mines => cache.putIfAbsent('mines', () => MarauderMines());
}

class MarauderMines extends Component with HasContext {
  late ComponentRecycler<MarauderMine> _mines;

  MarauderMine? spawn3d(FakeThreeDee origin, {double drift = 0}) =>
      spawn(origin.position, drift: drift, drop_height: origin.fake_height);

  MarauderMine? spawn(Vector2 position, {double drift = 0, double? drop_height}) =>
      stage.added(_mines.acquire()..reset(position, drift: drift, drop_height: drop_height));

  @override
  onLoad() => _mines = ComponentRecycler(() => MarauderMine(animCR('mine.png', 8, 1)));
}

class MarauderMine extends VoxelEntity with CollisionCallbacks, HasContext, EnemyHitPoints, Recyclable {
  MarauderMine(this.animation) {
    set_sprite_source(animation.frames.first.sprite, 8);

    scale_x = 1.2;
    scale_y = 1.8;
    scale_z = 1.2;
    size.setAll(16);

    add(CircleHitbox(radius: 6, anchor: Anchor.center, isSolid: true)..anchor_to_parent());
  }

  final _dir_override = Vector2.zero();

  void set_direction(Vector2 direction) => _dir_override.setFrom(direction);

  void reset(Vector2 origin, {double drift = 0, double? drop_height}) {
    fake_height = drop_height ?? 50;
    fake_height -= 5; // to appear underneath

    position.setFrom(origin);
    hit_time = 0;
    reset_hit_points_to(switch (difficulty) {
      Difficulty.easy => 10,
      Difficulty.normal => 15,
      Difficulty.hard => 20,
    });
    _became_visible = false;
    _destroyed = false;
    this.drift = drift;
    _dir_override.setZero();

    reset_sprite_data();

    _rotations.fill(0.0);
    _rotations[rng.nextInt(3)] = 2.5 + rng.nextDoubleLimit(0.5);
    if (video == VideoMode.quality) {
      _rotations[rng.nextInt(3)] = 2.5 + rng.nextDoubleLimit(0.5);
    }

    rot_x = rot_y = rot_z = 0;
  }

  final _rotations = List.filled(3, 0.0);

  final SpriteAnimation animation;

  double drift = 0.0;

  bool _became_visible = false;
  bool _destroyed = false;
  double _anim_time = 0;

  @override
  bool get susceptible => !_destroyed;

  @override
  void on_destroyed() {
    if (recycled) return;
    if (_destroyed) return;
    _destroyed = true;
    decals.spawn3d(Decal.nuke_explosion, this);
    recycle();

    audio.play(Sound.explosion_hollow, volume_factor: 0.25);
  }

  @override
  void onMount() {
    super.onMount();
    shadows.add(create_linked_shadow());
  }

  @override
  void update(double dt) {
    alreadyCollided.clear();

    super.update(dt);

    _anim_time += dt;

    if (_anim_time >= 1) _anim_time -= 1;

    if (rotate_mines) {
      rot_x += _rotations[0] * dt;
      rot_y += _rotations[1] * dt;
      rot_z += _rotations[2] * dt;
    }

    if (_dir_override.isZero()) {
      position.x -= 100 * dt;
      position.y += 100 / 4 * dt;
      position.x -= drift / 4 * dt;
      position.y -= drift * dt;
    } else {
      _tmp.setFrom(_dir_override);
      _tmp.scale(dt);
      position.add(_tmp);
    }

    final outside = position.is_outside();
    if (!outside) _became_visible = true;
    if (_became_visible && outside) recycle();
  }

  final _tmp = Vector2.zero();

  final _ours = Vector2.zero();
  final _theirs = Vector2.zero();

  static final alreadyCollided = <MarauderMine>[];

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (recycled) return;

    if (other is MarauderMine) {
      //
      // lovely work.. as always.. :-D
      //
      if (alreadyCollided.contains(this)) return;
      if (alreadyCollided.contains(other)) return;
      alreadyCollided.add(this);
      alreadyCollided.add(other);

      if (this._dir_override.isZero()) {
        _dir_override.x = -100 - drift / 4;
        _dir_override.y = 100 / 4 - drift;
      }
      if (other._dir_override.isZero()) {
        other._dir_override.x = -100 - other.drift / 4;
        other._dir_override.y = 100 / 4 - other.drift;
      }

      _ours.setFrom(this._dir_override);
      _ours.normalize();
      _theirs.setFrom(other._dir_override);
      _theirs.normalize();

      final m1 = 100.0;
      final m2 = 100.0;
      final u1 = _ours;
      final u2 = _theirs;
      final v1 = (u1 * (m1 - m2) + u2 * m2 * 2) / (m1 + m2);
      final v2 = (u2 * (m2 - m1) + u1 * m1 * 2) / (m1 + m2);
      this._dir_override.x = v1.x;
      this._dir_override.y = v1.y;
      other._dir_override.x = v2.x;
      other._dir_override.y = v2.y;
      this._dir_override.scale(100);
      other._dir_override.scale(100);

      return;
    }

    if (!other.hasTrait<Friendly>()) return;

    other.onTraits<Target>((it) {
      if (!it.susceptible) return;

      final damage = switch (difficulty) {
        Difficulty.easy => 40.0,
        Difficulty.normal => 60.0,
        Difficulty.hard => 80.0,
      };
      it.on_hit(damage: damage);

      position.x -= 10;
      position.y += 10 / 4;
      for (int i = 0; i < 5; i++) {
        final d = decals.spawn3d(Decal.mini_explosion, this);
        d.velocity.setValues(-10.0 * i, 10 / 4 * i);
        d.time = rng.nextDoubleLimit(0.2);
      }
      recycle();

      audio.play(Sound.explosion_hollow, volume_factor: 0.25);
    });
  }
}

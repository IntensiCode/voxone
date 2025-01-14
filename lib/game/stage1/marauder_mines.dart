import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/stacked_sprite.dart';

var rotate_mines = true;

extension HasContextExtensions on HasContext {
  MarauderMines get mines => cache.putIfAbsent('mines', () => MarauderMines());
}

class MarauderMines extends Component with HasContext {
  late ComponentRecycler<MarauderMine> _mines;

  MarauderMine? spawn(Vector2 position, {double drift = 0}) =>
      stage.added(_mines.acquire()..reset(position, drift: drift));

  @override
  onLoad() => _mines = ComponentRecycler(() => MarauderMine(animCR('mine.png', 8, 1), shadows));
}

class MarauderMine extends PositionComponent with CollisionCallbacks, HasContext, HasPaint, EnemyHitPoints, Recyclable {
  MarauderMine(this.animation, Shadows shadows)
      : entity = StackedEntity.sprite(animation.frames.first.sprite, 8, shadows) {
    entity.scale_x = 1.2;
    entity.scale_y = 1.8;
    entity.scale_z = 1.2;
    entity.size.setAll(16);

    add(entity);

    size.setAll(16);
    add(CircleHitbox(radius: 6, anchor: Anchor.center)..debug());
  }

  final _dir_override = Vector2.zero();

  void set_direction(Vector2 direction) => _dir_override.setFrom(direction);

  void reset(Vector2 origin, {double drift = 0}) {
    position.setFrom(origin);
    hit_time = 0;
    hit_points = 10;
    remaining = 10;
    _became_visible = false;
    _destroyed = false;
    this.drift = drift;
    _dir_override.setZero();

    entity.sprite.reset();
  }

  final SpriteAnimation animation;
  final StackedEntity entity;

  late ExtraId which;

  double drift = 0.0;

  bool _became_visible = false;
  bool _destroyed = false;
  double _anim_time = 0;

  @override
  bool get susceptible => !_destroyed;

  @override
  set highlight_mode(HighlightMode mode) => entity.sprite.highlight_mode = mode;

  @override
  void on_destroyed() {
    if (_destroyed) return;
    _destroyed = true;
    decals.spawn(Decal.nuke_explosion, position);
    recycle();

    audio.play(Sound.explosion_hollow, volume_factor: 0.25);
  }

  @override
  void update(double dt) {
    alreadyCollided.clear();

    super.update(dt);

    _anim_time += dt;

    if (_anim_time >= 1) _anim_time -= 1;

    if (rotate_mines) {
      entity.rot_x += dt;
      entity.rot_y += dt / 2;
      entity.rot_z += dt * 3;
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
        Difficulty.easy => 20.0,
        Difficulty.normal => 25.0,
        Difficulty.hard => 27.5,
      };
      it.on_hit(damage: damage);

      position.x -= 10;
      position.y += 10 / 4;
      for (int i = 0; i < 5; i++) {
        final d = decals.spawn(Decal.mini_explosion, position);
        d.velocity.setValues(-10.0 * i, 10 / 4 * i);
        d.time = rng.nextDoubleLimit(0.2);
      }
      recycle();

      audio.play(Sound.explosion_hollow, volume_factor: 0.25);
    });
  }
}

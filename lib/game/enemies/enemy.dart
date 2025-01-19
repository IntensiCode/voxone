import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/enemies/marauder_gun.dart';
import 'package:voxone/game/enemies/marauder_mines.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/enemy_explosion.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/enemy_wave.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/stacked_sprite.dart';

bool can_sweep = true;

mixin Enemy implements Hostile, Target {
  bool get defeated => state == EnemyState.defeated || state == EnemyState.left;

  bool get dead_or_gone => defeated || state == EnemyState.exploding || state == EnemyState.left;

  EnemyState get state;

  NotifyingVector2 get position;
}

enum EnemyState {
  incoming,
  active,
  sweeping,
  leaving,
  left,
  exploding,
  defeated,
  ;

  bool get is_inactive => [defeated, exploding, leaving, left].contains(this);
}

abstract class EnemyEntity extends PositionComponent with HasContext, Enemy, EnemyHitPoints, FakeThreeDee {
  EnemyEntity(this.wave);

  final EnemyWave wave;

  late final StackedEntity entity;

  @override
  EnemyState state = EnemyState.incoming;

  final target_position = Vector2.zero();

  double volatile_incoming_time = 0.9;

  @override
  bool get susceptible => switch (state) {
        EnemyState.left => false,
        EnemyState.exploding => false,
        EnemyState.defeated => false,
        EnemyState.incoming => incoming_time > volatile_incoming_time,
        _ => true,
      };

  @override
  set highlight_mode(HighlightMode mode) => entity.sprite.highlight_mode = mode;

  void set_active_collisions() {
    for (final it in children.whereType<ShapeHitbox>()) {
      it.collisionType = CollisionType.active;
    }
  }

  double _explode_delay = 0;
  double _explode_scale = 1;

  @override
  void on_destroyed({Vector2? direction}) {
    if (state == EnemyState.exploding) return;
    state = EnemyState.exploding;

    wave.killed.add(this);

    if (sweep_time > 0) can_sweep = true;

    leaving_time = 0;
    _explode_delay = 0.01 + rng.nextDoubleLimit(0.25);
    _explode_scale = 1 + rng.nextDoublePM(0.25);

    // entity.add(EnemyExplosion());
    // audio.play(Sound.explosion, volume_factor: 0.25);

    tumble_dir.setFrom(direction ?? raw_dir);
    tumble_dir.normalize();
    tumble_dir.scale(50);
  }

  @override
  void onLoad() {
    super.onLoad();
    createEntity();
    position.setFrom(target_position);
    fake_height = 50;
  }

  void createEntity();

  double active_time_limit = 120;

  double incoming_time = 0;
  double active_time = 0;
  double leaving_time = 0;

  double sweep_time = 0;
  double sweep_dist = 0;
  bool mine_planted = false;

  // fix(?) for recycled mines position bug
  final _live_position = Vector2.zero();

  // updated each frame in on_active
  final raw_dir = Vector2.zero();

  // set from raw_dir in on_destroyed - used for movement while exploding
  final tumble_dir = Vector2.zero();

  double _last_explosion_time = 0;

  @override
  void update(double dt) {
    _last_explosion_time = min(0.25, _last_explosion_time + dt);
    _live_position.setFrom(position);
    super.update(dt);
    switch (state) {
      case EnemyState.incoming:
        on_incoming(dt);

      case EnemyState.active:
        on_active(dt);
        if (player.is_dead_or_dying()) {
          if (state == EnemyState.active) state = EnemyState.leaving;
          if (state == EnemyState.sweeping) state = EnemyState.leaving;
        }

      case EnemyState.sweeping:
        on_sweeping(dt);

      case EnemyState.leaving:
        on_leaving(dt);

      case EnemyState.left:
        removeFromParent();

      case EnemyState.exploding:
        if (_explode_delay > 0) {
          _on_explode_delay(dt);
        } else {
          on_exploding(dt * _explode_scale);
        }

      case EnemyState.defeated:
        removeFromParent();
    }
    raw_dir.setFrom(position);
    raw_dir.sub(_live_position);
  }

  void _on_explode_delay(double dt) {
    _explode_delay = max(0, _explode_delay - dt);
    if (_explode_delay > 0) return;

    add(explosions.spawn(entity));
    if (_last_explosion_time >= 0.25) {
      audio.play(Sound.explosion, volume_factor: 0.25);
    }
    _last_explosion_time = 0;
  }

  void on_incoming(double dt);

  void on_active(double dt);

  void on_sweeping(double dt);

  void on_leaving(double dt);

  void on_exploding(double dt);
}

mixin CreateMarauderEntity on EnemyEntity {
  @override
  void createEntity() {
    reset_hit_points_to(dev ? 3 : 25);

    fake_height = 50;

    size.setAll(180);

    entity = StackedEntity('entities/transstellar.png', 14, shadows);
    entity.size.setAll(256);
    entity.rot_x = -pi / 8;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8;
    entity.scale_x = 1.2;
    entity.scale_y = 3.5;
    entity.scale_z = 1.2;

    entity.add(EnemyHealthBar(this));
    add(entity);
    add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)..debug());
    add(MarauderGun(this));
  }
}

mixin SweepInOnIncoming on EnemyEntity {
  @override
  void on_incoming(double dt) {
    incoming_time += dt * 2 / 3;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = EnemyState.active;
    }

    fake_height = 50 + 150 * (1 - incoming_time);
    base_scale = 0.2;
    descale = 1000;
    scale.setAll((1 - incoming_time) * 0.5 + 0.2);

    final i = Curves.easeInOut.transform(incoming_time);
    position.setFrom(target_position);
    position.x += 350;
    position.x -= 350 * i;
  }
}

mixin AddShieldAfterOnIncoming on EnemyEntity, HasTraits {
  late DeflectorShield shield;
  late EnemyHealthBar indicator;

  String shield_shader = 'plasma_shield.frag';

  @override
  void on_incoming(double dt) {
    super.on_incoming(dt);

    if (incoming_time < 1) return;

    shield = DeflectorShield(this, shader_name: shield_shader);
    shield.auto_recharge = 0.01;
    shield.addTrait(Hostile());
    add(shield);
    addTrait(shield);

    entity.add(indicator = EnemyHealthBar(shield)..position.setValues(0, -64));

    shield_added();

    shielded = true;
  }

  void shield_added() {}

  bool shielded = false;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    if (shielded && shield.energy > 0.1) {
      super.on_hit(intersections: intersections, damage: damage * 0.1);
    } else {
      super.on_hit(intersections: intersections, damage: damage);
    }
  }

  @override
  void on_destroyed({Vector2? direction}) {
    super.on_destroyed(direction: direction);
    if (state.is_inactive && shielded && shield.isMounted) {
      if (shield.isRemoving) return;
      shield.removeFromParent();
      indicator.removeFromParent();
    }
  }
}

mixin FloatOnActive on EnemyEntity {
  @override
  void on_active(double dt) {
    scale.setAll(sin(active_time / 3) * 0.025 + 0.2);
    entity.rot_x = -pi / 8 + sin(active_time / 7) * 0.2;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8 + sin(active_time) * 0.2;
    active_time += dt * 3;
    position.setFrom(target_position);
    position.x += sin(active_time / 1.2345) * 10;
    position.y += sin(active_time) * 10;

    if (state != EnemyState.active) {
      return;
    } else if (active_time > active_time_limit) {
      state = EnemyState.leaving;
    } else if (can_sweep && rng.nextDouble() < 0.2) {
      can_sweep = false;
      sweep_time = 0;
      sweep_dist = 300 - target_position.x;
      state = EnemyState.sweeping;
    }
  }
}

mixin NopOnSweeping on EnemyEntity {
  @override
  void on_sweeping(double dt) {
    on_active(dt); // to keep position and scale in sync after sweep
    can_sweep = true;
    state = EnemyState.active;
  }
}

mixin PlantMineOnSweeping on EnemyEntity {
  @override
  void on_sweeping(double dt) {
    on_active(dt); // to keep position and scale in sync after sweep

    entity.sprite.cache = false;

    sweep_time += dt;
    if (sweep_time >= 10) {
      can_sweep = true;
      mine_planted = false;
      sweep_time = 0;
      state = EnemyState.active;
      entity.sprite.cache = true;
      return;
    }

    if (sweep_time >= 5 && !mine_planted) {
      mine_planted = true;
      mines.spawn(_live_position);
    }

    final t = Curves.easeInOutCubic.transform(sweep_time / 10);
    final x = sin(t * pi) * sweep_dist;
    position.x += x;
    scale.x += sin(t * pi) / 10;
    scale.y += sin(t * pi) / 10;

    double mm = sweep_time < 5 ? 0 : 0.5 + (sweep_time - 5) / 10;
    double m = Curves.easeInOut.transform(mm);
    entity.rot_x -= sin(m * pi * 8 / 4) * pi / 4;
    entity.rot_y -= sin(m * pi * 8 / 4) * pi / 1;
    entity.rot_z += sin(m * pi * 8 / 4) * pi / 2;
  }
}

mixin NopOnLeaving on EnemyEntity {
  @override
  void on_leaving(double dt) {
    state = EnemyState.active;
  }
}

mixin SweepOutOnLeaving on EnemyEntity {
  @override
  void on_leaving(double dt) {
    on_active(dt);

    leaving_time += dt;
    if (leaving_time >= 2) {
      leaving_time = 2;
      state = EnemyState.left;
    }

    scale.x += leaving_time * 0.5;
    scale.y += leaving_time * 0.5;

    final i = Curves.easeInOut.transform(leaving_time / 2);
    position.y -= 550 * i;
    position.x -= 550 * i / 4;
  }
}

mixin TumbleOnExploding on EnemyEntity {
  @override
  void on_exploding(double dt) {
    leaving_time += dt;
    if (leaving_time >= 2) {
      leaving_time = 2;
      state = EnemyState.defeated;
    }

    entity.rot_x += dt;
    entity.rot_y += dt * 2;
    entity.rot_z += dt * 0.5;
    position.x += dt * tumble_dir.x;
    position.y += dt * tumble_dir.y;

    entity.sprite.opacity = 1 - leaving_time / 2;
  }
}

mixin SpawnExtrasOnExploding on EnemyEntity {
  int random_extras_count = 1;
  Set<ExtraId> allowed_random_extras = ExtraId.defaults;
  Set<ExtraId>? required_extras;

  bool _extras_spawned = false;

  @override
  void on_exploding(double dt) {
    super.on_exploding(dt);

    if (leaving_time < 1 || _extras_spawned) return;

    if (wave.kill_bonus) {
      wave.killed.clear();
      spawn_bonus();
    } else {
      spawn_default();
    }

    _extras_spawned = true;
  }

  void spawn_default() => _spawn_extras(required_extras ?? {}, random_extras_count);

  void spawn_bonus() {
    final bonus = {ExtraId.primaries.random(rng), ExtraId.secondaries.random(rng)};
    _spawn_extras(required_extras ?? bonus, random_extras_count + 3);
    audio.play(Sound.bonus1, volume_factor: 0.5);
  }

  void _spawn_extras(Set<ExtraId> required, int random_count) {
    final all_count = required.length + random_count;
    var index = 0;
    for (final e in required) {
      extras.spawn3d(this, choices: {e}, index: index++, count: all_count);
    }
    random_count.forEach((_) {
      extras.spawn3d(this, choices: allowed_random_extras, index: index++, count: all_count);
    });
  }
}

mixin ActiveOnIncoming on EnemyEntity {
  @override
  void on_incoming(double dt) => state = EnemyState.active;
}

mixin DelayOnIncoming on EnemyEntity, HasVisibility {
  double incoming_delay = 0;

  @override
  void on_incoming(double dt) {
    if (incoming_delay > 0) incoming_delay -= dt;
    if (incoming_delay <= 0) {
      incoming_time = 1;
      state = EnemyState.active;
    }
    isVisible = incoming_delay <= 0;
  }
}

mixin WarpInOnIncoming on EnemyEntity {
  @override
  void on_incoming(double dt) {
    incoming_time += dt * 2 / 3;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = EnemyState.active;
      entity.sprite.paint.imageFilter = null;
      entity.sprite.paint.colorFilter = null;
    }
    scale.setAll(0.2);
    scale.x += 4 - incoming_time * 4;

    final i = Curves.easeInOut.transform(incoming_time);
    position.setFrom(target_position);
    position.x += 550;
    position.x -= 550 * i;

    entity.sprite.opacity = incoming_time;

    entity.sprite.paint.imageFilter = ImageFilter.blur(sigmaX: 32 * (1 - i), sigmaY: 32 * (1 - i));
    entity.sprite.paint.colorFilter = ColorFilter.mode(white, BlendMode.modulate);
  }
}

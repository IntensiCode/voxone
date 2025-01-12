import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/enemy_explosion.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/stage1/marauder_gun.dart';
import 'package:voxone/game/stage1/marauder_mines.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/util/stacked_sprite.dart';

bool can_sweep = true;

mixin Marauder implements Hostile, Target {
  bool get defeated => state == MarauderState.defeated || state == MarauderState.left;

  MarauderState get state;

  NotifyingVector2 get position;
}

enum MarauderState {
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

abstract class MarauderEntity extends PositionComponent with HasContext, Marauder, EnemyHitPoints {
  late final StackedEntity entity;

  @override
  MarauderState state = MarauderState.incoming;

  final target_position = Vector2.zero();

  double volatile_incoming_time = 0.9;

  @override
  bool get susceptible => switch (state) {
        MarauderState.left => false,
        MarauderState.exploding => false,
        MarauderState.defeated => false,
        MarauderState.incoming => incoming_time > volatile_incoming_time,
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
    if (state == MarauderState.exploding) return;
    state = MarauderState.exploding;

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
  Future onLoad() async {
    super.onLoad();
    createEntity();
    position.setFrom(target_position);
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
      case MarauderState.incoming:
        on_incoming(dt);

      case MarauderState.active:
        on_active(dt);
        if (player.is_dead_or_dying()) {
          if (state == MarauderState.active) state = MarauderState.leaving;
          if (state == MarauderState.sweeping) state = MarauderState.leaving;
        }

      case MarauderState.sweeping:
        on_sweeping(dt);

      case MarauderState.leaving:
        on_leaving(dt);

      case MarauderState.left:
        removeFromParent();

      case MarauderState.exploding:
        if (_explode_delay > 0) {
          _on_explode_delay(dt);
        } else {
          on_exploding(dt * _explode_scale);
        }

      case MarauderState.defeated:
        removeFromParent();
    }
    raw_dir.setFrom(position);
    raw_dir.sub(_live_position);
  }

  void _on_explode_delay(double dt) {
    _explode_delay = max(0, _explode_delay - dt);
    if (_explode_delay > 0) return;

    add(EnemyExplosion(entity));
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

mixin CreateMarauderEntity on MarauderEntity {
  @override
  createEntity() async {
    reset_hit_points_to(dev ? 3 : 25);

    size.setAll(180);

    entity = StackedEntity('entities/transstellar.png', 14, shadows);
    entity.size.setAll(256);
    entity.rot_x = -pi / 8;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8;
    entity.scale_x = 1.2;
    entity.scale_y = 3.5;
    entity.scale_z = 1.2;

    await entity.add(EnemyHealthBar(this));
    await add(entity);
    await add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)..debug());
    await add(MarauderGun(this));
  }
}

mixin SweepInOnIncoming on MarauderEntity {
  @override
  void on_incoming(double dt) {
    incoming_time += dt * 2 / 3;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = MarauderState.active;
    }
    scale.setAll((1 - incoming_time) * 0.5 + 0.2);
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(incoming_time);
    position.setFrom(target_position);
    position.x += 350;
    position.x -= 350 * i;
  }
}

mixin AddShieldAfterOnIncoming on MarauderEntity, HasTraits {
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

mixin FloatOnActive on MarauderEntity {
  @override
  void on_active(double dt) {
    scale.setAll(sin(active_time / 3) * 0.025 + 0.2);
    priority = (scale.x * 1000).toInt();
    entity.rot_x = -pi / 8 + sin(active_time / 7) * 0.2;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8 + sin(active_time) * 0.2;
    active_time += dt * 3;
    position.setFrom(target_position);
    position.x += sin(active_time / 1.2345) * 10;
    position.y += sin(active_time) * 10;

    if (state != MarauderState.active) {
      return;
    } else if (active_time > active_time_limit) {
      state = MarauderState.leaving;
    } else if (can_sweep && rng.nextDouble() < 0.2) {
      can_sweep = false;
      sweep_time = 0;
      sweep_dist = 300 - target_position.x;
      state = MarauderState.sweeping;
    }
  }
}

mixin NopOnSweeping on MarauderEntity {
  @override
  void on_sweeping(double dt) {
    on_active(dt); // to keep position and scale in sync after sweep
    can_sweep = true;
    state = MarauderState.active;
  }
}

mixin PlantMineOnSweeping on MarauderEntity {
  @override
  void on_sweeping(double dt) {
    on_active(dt); // to keep position and scale in sync after sweep

    sweep_time += dt;
    if (sweep_time >= 10) {
      can_sweep = true;
      mine_planted = false;
      sweep_time = 0;
      state = MarauderState.active;
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
    priority = (scale.x * 1000).toInt();

    double mm = sweep_time < 5 ? 0 : 0.5 + (sweep_time - 5) / 10;
    double m = Curves.easeInOut.transform(mm);
    entity.rot_x -= sin(m * pi * 8 / 4) * pi / 4;
    entity.rot_y -= sin(m * pi * 8 / 4) * pi / 1;
    entity.rot_z += sin(m * pi * 8 / 4) * pi / 2;
  }
}

mixin NopOnLeaving on MarauderEntity {
  @override
  void on_leaving(double dt) {
    state = MarauderState.active;
  }
}

mixin SweepOutOnLeaving on MarauderEntity {
  @override
  void on_leaving(double dt) {
    on_active(dt);

    leaving_time += dt;
    if (leaving_time >= 2) {
      leaving_time = 2;
      state = MarauderState.left;
    }

    scale.x += leaving_time * 0.5;
    scale.y += leaving_time * 0.5;
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(leaving_time / 2);
    position.y -= 550 * i;
    position.x -= 550 * i / 4;
  }
}

mixin TumbleOnExploding on MarauderEntity {
  @override
  void on_exploding(double dt) {
    leaving_time += dt;
    if (leaving_time >= 2) {
      leaving_time = 2;
      state = MarauderState.defeated;
    }

    entity.rot_x += dt;
    entity.rot_y += dt * 2;
    entity.rot_z += dt * 0.5;
    position.x += dt * tumble_dir.x;
    position.y += dt * tumble_dir.y;

    entity.sprite.opacity = 1 - leaving_time / 2;
  }
}

mixin SpawnExtrasOnExploding on MarauderEntity {
  bool get _last_remaining => stage.children.whereType<Marauder>().singleOrNull == this;

  int random_extras_count = 1;
  Set<ExtraId> allowed_random_extras = ExtraId.defaults;
  Set<ExtraId>? required_extras;

  bool _extras_spawned = false;

  @override
  void on_exploding(double dt) {
    super.on_exploding(dt);

    if (leaving_time < 1 || _extras_spawned) return;

    final required = required_extras ?? {};
    final random_count = random_extras_count + (_last_remaining ? 3 : 0);
    final all_count = required.length + random_count;
    var index = 0;
    for (final e in required) {
      extras.spawn(position, choices: {e}, index: index++, count: all_count);
    }
    random_count.forEach((_) {
      extras.spawn(position, choices: allowed_random_extras, index: index++, count: all_count);
    });

    _extras_spawned = true;
  }
}

mixin ActiveOnIncoming on MarauderEntity {
  @override
  void on_incoming(double dt) => state = MarauderState.active;
}

mixin DelayOnIncoming on MarauderEntity, HasVisibility {
  double incoming_delay = 0;

  @override
  void on_incoming(double dt) {
    if (incoming_delay > 0) incoming_delay -= dt;
    if (incoming_delay <= 0) {
      incoming_time = 1;
      state = MarauderState.active;
    }
    isVisible = incoming_delay <= 0;
  }
}

mixin WarpInOnIncoming on MarauderEntity {
  @override
  void on_incoming(double dt) {
    incoming_time += dt * 2 / 3;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = MarauderState.active;
      entity.sprite.paint.imageFilter = null;
      entity.sprite.paint.colorFilter = null;
    }
    scale.setAll(0.2);
    scale.x += 4 - incoming_time * 4;
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(incoming_time);
    position.setFrom(target_position);
    position.x += 550;
    position.x -= 550 * i;

    entity.sprite.opacity = incoming_time;

    entity.sprite.paint.imageFilter = ImageFilter.blur(sigmaX: 32 * (1 - i), sigmaY: 32 * (1 - i));
    entity.sprite.paint.colorFilter = ColorFilter.mode(white, BlendMode.modulate);
  }
}

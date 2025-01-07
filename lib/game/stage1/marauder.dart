import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:voxone/aural/soundboard.dart';
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

  @override
  bool get susceptible => switch (state) {
        MarauderState.left => false,
        MarauderState.exploding => false,
        MarauderState.defeated => false,
        _ => incoming_time > 0.9,
      };

  @override
  set highlight_mode(HighlightMode mode) => entity.sprite.highlight_mode = mode;

  @override
  void on_destroyed() {
    if (state == MarauderState.exploding) return;
    state = MarauderState.exploding;
    entity.add(EnemyExplosion());
    if (sweep_time > 0) can_sweep = true;
    soundboard.play(Sound.explosion);
  }

  @override
  Future onLoad() async {
    super.onLoad();
    createEntity();
    position.setFrom(target_position);
  }

  void createEntity();

  double incoming_time = 0;
  double active_time = 0;
  double leaving_time = 0;

  double sweep_time = 0;
  double sweep_dist = 0;
  bool mine_planted = false;
  int random_extras_count = 1;
  Set<ExtraId> allowed_random_extras = ExtraId.restore;
  Set<ExtraId>? required_extras;

  @override
  void update(double dt) {
    super.update(dt);
    switch (state) {
      case MarauderState.incoming:
        on_incoming(dt);

      case MarauderState.active:
        on_active(dt);

      case MarauderState.sweeping:
        on_sweeping(dt);

      case MarauderState.leaving:
        on_leaving(dt);

      case MarauderState.left:
        removeFromParent();

      case MarauderState.exploding:
        on_exploding(dt);

      case MarauderState.defeated:
        removeFromParent();
    }
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

    await add(RectangleHitbox(collisionType: CollisionType.passive, anchor: Anchor.center)
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

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

  String shader_name = 'plasma_shield.frag';

  @override
  void on_incoming(double dt) {
    super.on_incoming(dt);

    if (incoming_time < 1) return;

    shield = DeflectorShield(this, shader_name: shader_name);
    shield.auto_recharge = 0.01;
    shield.addTrait(Hostile());
    add(shield);
    addTrait(shield);

    entity.add(indicator = EnemyHealthBar(shield)..position.setValues(0, -64));

    shield_added();
  }

  void shield_added() {}

  @override
  void on_destroyed() {
    super.on_destroyed();
    if (state.is_inactive && shield.isMounted) {
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
    } else if (active_time > 120) {
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
      mines.spawn(position);
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
  bool extra_spawned = false;

  @override
  void on_exploding(double dt) {
    leaving_time += dt;
    if (leaving_time >= 1) {
      if (!extra_spawned) {
        for (final e in required_extras ?? {}) {
          extras.spawn(position, choices: {e});
        }
        random_extras_count.forEach((_) {
          extras.spawn(position, choices: allowed_random_extras);
        });
      }
      extra_spawned = true;
    }
    if (leaving_time >= 2) {
      leaving_time = 2;
      state = MarauderState.defeated;
    }

    entity.rot_x += dt;
    entity.rot_y += dt * 2;
    entity.rot_z += dt * 0.5;
    position.x -= dt * 100;
    position.y += dt * 100 / 4;

    entity.sprite.opacity = 1 - leaving_time / 2;
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

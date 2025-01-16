import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/vox.dart';
import 'package:voxone/game/enemies/enemy.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/enemy_health_bar.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';
import 'package:voxone/voxel/vox_io.dart';

class ReconMech extends EnemyEntity
    with
        CollisionCallbacks,
        _CreateReconMechEntity,
        HasVisibility,
        DelayOnIncoming,
        _MoveOnActive,
        NopOnSweeping,
        NopOnLeaving,
        TumbleOnExploding,
        SpawnExtrasOnExploding {
  ReconMech(super.wave);

  static Future preload() async {
    final voxels = _CreateReconMechEntity._voxels ??= await vox('recon_mech.vx');
    _CreateReconMechEntity._image ??= vox_to_image_ext(voxels);
  }

  @override
  bool get susceptible => (entity.fake_height ?? 0) > 30;

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Player && susceptible) {
      on_destroyed(direction: Vector2(rng.nextDoubleLimit(50) + 20, rng.nextDoublePM(40)));
      (other as Target).on_hit(intersections: intersectionPoints, damage: 30);
    }
  }
}

mixin _CreateReconMechEntity on EnemyEntity {
  static Voxels? _voxels;
  static Image? _image;

  static final _pick_start_pos = <int>[];

  @override
  void createEntity() {
    reset_hit_points_to(10);

    anchor = Anchor.center;
    size.setAll(200);
    scale.setAll(0.2);

    if (_pick_start_pos.isEmpty) {
      _pick_start_pos.addAll(List.generate(8, (i) => i));
    }
    final start_pos = _pick_start_pos.removeAt(rng.nextInt(_pick_start_pos.length));
    target_position.x = 1000;
    target_position.y = start_pos * 50 - 50;

    entity = StackedEntity.sprite(Sprite(_image!), _voxels!.height, shadows);
    entity.size.x = _voxels!.width.toDouble();
    entity.size.y = _voxels!.height.toDouble();
    entity.anchor = Anchor.center;
    entity.position.setFrom(size / 4);
    entity.size.setAll(250);
    entity.rot_x = -pi / 8;
    entity.rot_y = -pi / 2 + pi / 8;
    entity.rot_z = -pi / 8;
    entity.scale_x = 1.2;
    entity.scale_y = 1.2;
    entity.scale_z = 1.2;

    entity.loaded.then((_) => entity.fake_height = 0);

    entity.add(EnemyHealthBar(this));
    add(entity);

    final hitbox = added(CircleHitbox(anchor: Anchor.center, radius: 40, isSolid: true)..debug());
    hitbox.position.setFrom(size / 2);
    hitbox.x -= 20;
  }
}

mixin _MoveOnActive on EnemyEntity {
  double jump_height = 50;

  double _jump_time = 0;
  double _down_time = 2;

  @override
  void on_active(double dt) {
    target_position.x -= 100 * dt;
    target_position.y += 25 * dt;

    position.setFrom(target_position);

    if (_down_time <= 0 && _jump_time <= 0 && rng.nextInt(10) == 0) {
      _jump_time = 2;
      _down_time = 2;
      final count = 8;
      count.forEach((i) {
        final dx = sin(i * pi * 2 / count) * 10;
        final dy = cos(i * pi * 2 / count) * 10;
        decals.spawn3d(Decal.dust, this).velocity.setValues(-100 + dx, -25 + dy);
      });
    }

    if (_jump_time > 0) {
      final i = (_jump_time % 1).clamp(0, 1);
      final j = switch (_jump_time) {
        < 1 => jump_height * sin(i * pi / 2),
        < 2 => jump_height * sin((1 + i) * pi / 2),
        _ => 0.0,
      };
      position.y -= j;
      entity.fake_height = j;

      target_position.x += 100 * dt;
      target_position.y -= 25 * dt;

      _jump_time -= dt;

      if (_jump_time <= 0) {
        final count = 16;
        count.forEach((i) {
          final dx = sin(i * pi * 2 / count) * 10;
          final dy = cos(i * pi * 2 / count) * 10;
          decals.spawn3d(Decal.dust, this).velocity.setValues(-100 + dx, -25 + dy);
        });
      }
    } else if (_down_time > 0) {
      _down_time -= dt;
    }

    if (position.x < -100) {
      state = EnemyState.left;
      removeFromParent();
    }
  }
}

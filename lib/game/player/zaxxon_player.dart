import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/player_state.dart';
import 'package:voxone/game/player/player_strafe.dart';
import 'package:voxone/game/player/weapon_system.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';

class ZaxxonPlayer extends PositionComponent
    with HasContext, HasTraits, PlayerStrafe
    implements Friendly, Player, Target {
  //
  late final StackedEntity _entity;

  PlayerState _state = PlayerState.incoming;

  PlayerState get state => _state;

  set state(PlayerState value) {
    logInfo(value);
    _state = value;
  }

  late final weapons = added(WeaponSystem(this));

  @override
  double integrity = 1;

  @override
  bool get susceptible => true;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    integrity -= damage / 50;
    if (integrity < 0) integrity = 0;
  }

  @override
  void on_collect_extra(ExtraId which) {
    logInfo('collect extra $which');
    switch (which) {
      case ExtraId.full_integrity:
        info('Integrity restored', hud: true);
        integrity = 1;
        break;
      case ExtraId.full_shield:
        info('Shield restored', hud: true);
        onTraits<DeflectorShield>((it) => it.shield.recharge(1));
        break;
      case ExtraId.integrity:
        info('Integrity boost', hud: true);
        integrity = min(1, integrity + 0.25);
        break;
      case ExtraId.shield:
        info('Shield boost', hud: true);
        onTraits<DeflectorShield>((it) => it.shield.recharge(0.25));
        break;
      case ExtraId.triple_plasma:
        info('Triple Plasma', title: 'Primary Weapon Upgrade', hud: true);
        logWarn('triple plasma not implemented');
        break;
      case _:
        info(which.toString(), title: 'Primary Weapon Upgrade', hud: true);
        logWarn('unhandled extra $which');
        break;
    }
  }

  @override
  Future onLoad() async {
    super.onLoad();

    addTrait(weapons);

    _entity = StackedEntity('entities/star_runner.png', 16, shadows);

    _entity.rot_x = -0.95;
    _entity.rot_y = 1.8;
    _entity.rot_z = -0.2;
    _entity.scale_x = 1.2;
    _entity.scale_y = 2.5;
    _entity.scale_z = 1.2;
    scale.setAll(0.3);
    _entity.size.setAll(256);
    position.setValues(100, 280);

    await add(_entity);

    size.setAll(256 * 0.3);

    await add(CircleHitbox(
      radius: 16,
      position: Vector2(-10, 2),
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    )
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    await add(CircleHitbox(
      radius: 8,
      position: Vector2(15, -5),
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    )
      ..paint.color = red
      ..opacity = 0.2
      ..renderShape = debug);

    final shield = DeflectorShield(this);
    shield.scale.setAll(4);
    shield.addTrait(Friendly());
    await add(shield);
    addTrait(shield);

    priority = 100;
  }

  double _incoming_time = 0;

  @override
  void update(double dt) {
    switch (state) {
      case PlayerState.incoming:
        _on_incoming(dt);
        break;

      case PlayerState.playing:
        update_strafe(dt);
        break;

      case PlayerState.exploding:
        break;

      case PlayerState.destroyed:
        break;
    }
  }

  void _on_incoming(double dt) {
    _incoming_time += dt * 2 / 3;
    if (_incoming_time >= 1) {
      _incoming_time = 1;
      state = PlayerState.playing;
      sendMessage(PlayerReady());
    }
    scale.setAll(0.3);
    _entity.size.setAll(256);

    final i = Curves.easeOut.transform(_incoming_time);
    position.setValues(-50 + 150 * i, 280 + 50 - 50 * i);
  }

  @override
  void set_strafe(double tilt, double move_offset) {
    super.set_strafe(tilt, move_offset);
    _entity.rot_x = tilt;
    position.setValues(100 + move_offset / 4, 280 + move_offset);
  }
}

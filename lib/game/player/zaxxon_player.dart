import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/acid_blaster.dart';
import 'package:voxone/game/player/cluster_bomb_cannon.dart';
import 'package:voxone/game/player/ion_pulse_gun.dart';
import 'package:voxone/game/player/nuke_missile_launcher.dart';
import 'package:voxone/game/player/plasma_emitter.dart';
import 'package:voxone/game/player/player_state.dart';
import 'package:voxone/game/player/player_strafe.dart';
import 'package:voxone/game/player/smart_bomb.dart';
import 'package:voxone/game/player/swirl_gun.dart';
import 'package:voxone/game/player/triple_plasma_gun.dart';
import 'package:voxone/game/player/weapon_system.dart';
import 'package:voxone/game/player/yin_yang_gun.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/extensions.dart';

enum _SoundHint {
  danger,
  none,
  warning,
}

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

  double _integrity_boost = 1;

  var _hint = _SoundHint.none;

  double _hint_time = 0;

  @override
  double integrity = 1;

  @override
  bool get susceptible => true;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    final was = integrity;
    integrity -= damage / 50 / _integrity_boost;
    if (integrity < 0) integrity = 0;
    if (integrity == 0 && was > 0.5) {
      integrity = 0.15;
      _hint = _SoundHint.danger;
    } else {
      _update_sound_hint();
    }
  }

  void _update_sound_hint() {
    if (integrity <= 0.15) {
      _hint = _SoundHint.danger;
    } else if (integrity <= 0.35) {
      _hint = _SoundHint.warning;
    } else {
      _hint = _SoundHint.none;
    }
  }

  @override
  void on_collect_extra(ExtraId which) {
    switch (which) {
      case ExtraId.acid_blast:
        final upgrade = weapons.switch_primary_to(AcidBlaster);
        info('Acid Blast', title: upgrade ? 'Primary Weapon' : null, hud: true);
        break;
      case ExtraId.cluster_bomb:
        info('Cluster Bomb', title: 'Secondary Weapon', hud: true);
        weapons.switch_secondary_to(ClusterBombCannon);
        break;
      case ExtraId.cooldown:
        info('Secondary Cooldown', hud: true);
        weapons.on_secondary_cooldown(0.5);
        break;
      case ExtraId.cooldown_boost:
        info('Cooldown Boost', hud: true);
        weapons.on_cooldown_boost();
        break;
      case ExtraId.integrity_boost:
        info('Integrity Boost', hud: true);
        _integrity_boost = min(2, _integrity_boost + 0.1);
        _update_sound_hint();
        break;
      case ExtraId.shield_boost:
        info('Shield Boost', hud: true);
        onTraits<DeflectorShield>((it) => it.on_shield_boost());
        break;
      case ExtraId.integrity:
        info('Integrity Repair', hud: true);
        integrity = min(1, integrity + 0.25);
        _update_sound_hint();
        break;
      case ExtraId.ion_pulse:
        final upgrade = weapons.switch_primary_to(IonPulseGun);
        info('Ion Pulse', title: upgrade ? 'Primary Weapon' : null, hud: true);
        break;
      case ExtraId.nuke_missile:
        info('Nuke Missile', title: 'Secondary Weapon', hud: true);
        weapons.switch_secondary_to(NukeMissileLauncher);
        break;
      case ExtraId.phosphor_swirl:
        final upgrade = weapons.switch_primary_to(SwirlGun);
        info('Phosphor Swirl', title: upgrade ? 'Primary Weapon' : null, hud: true);
        break;
      case ExtraId.plasma_ring:
        info('Plasma Ring', title: 'Secondary Weapon', hud: true);
        weapons.switch_secondary_to(PlasmaEmitter);
        break;
      case ExtraId.shield:
        info('Shield Repair', hud: true);
        onTraits<DeflectorShield>((it) => it.shield.recharge(0.25));
        break;
      case ExtraId.smart_bomb:
        info('Smart Bomb', title: 'Secondary Weapon', hud: true);
        weapons.switch_secondary_to(SmartBomb);
        break;
      case ExtraId.triple_plasma:
        final upgrade = weapons.switch_primary_to(TriplePlasmaGun);
        info('Triple Plasma', title: upgrade ? 'Primary Weapon' : null, hud: true);
        break;
      case ExtraId.yin_yang:
        final upgrade = weapons.switch_primary_to(YinYangGun);
        info('Yin Yang', title: upgrade ? 'Primary Weapon' : null, hud: true);
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
    super.update(dt);

    _update_sound(dt);

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

  void _update_sound(double dt) {
    if (_hint_time > 0) _hint_time = max(0, _hint_time - dt);

    if (_hint != _SoundHint.none && _hint_time <= 0) {
      _hint_time = 2;
      final name = switch (_hint) {
        _SoundHint.danger => 'danger',
        _SoundHint.warning => 'warning',
        _SoundHint.none => 'none',
      };
      audio.play_one_shot_sample('voice/$name.ogg', volume_factor: 2);
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

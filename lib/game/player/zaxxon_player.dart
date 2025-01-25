import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/player_strafe.dart';
import 'package:voxone/game/player/weapon_system.dart';
import 'package:voxone/game/player/weapons/acid_blaster.dart';
import 'package:voxone/game/player/weapons/cluster_bomb_cannon.dart';
import 'package:voxone/game/player/weapons/ion_pulse_gun.dart';
import 'package:voxone/game/player/weapons/nuke_missile_launcher.dart';
import 'package:voxone/game/player/weapons/plasma_emitter.dart';
import 'package:voxone/game/player/weapons/plasma_gun.dart';
import 'package:voxone/game/player/weapons/smart_bomb.dart';
import 'package:voxone/game/player/weapons/swirl_gun.dart';
import 'package:voxone/game/player/weapons/yin_yang_gun.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/deflector_shield.dart';
import 'package:voxone/game/shared/enemy_explosion.dart';
import 'package:voxone/game/shared/enemy_hit_points.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/game_phase.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/player_state.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/game/shared/voxel_entity.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';

enum _SoundHint {
  danger,
  none,
  warning,
}

class ZaxxonPlayer extends VoxelEntity
    with
        AutoDispose,
        HasAutoDisposeShortcuts,
        HasContext,
        HasTraits,
        Player,
        Target,
        _CreateEntityOnLoad,
        _CollectExtras,
        PlayerStrafe
    implements Friendly {
  //
  PlayerState _state = PlayerState.incoming;

  bool invincible = false;

  @override
  PlayerState get state => _state;

  set state(PlayerState value) {
    logInfo(value);
    _state = value;
  }

  @override
  bool get susceptible => stage.phase == GamePhase.playing;

  @override
  void on_hit({Set<Vector2>? intersections, double damage = 1}) {
    if (invincible || is_dead_or_dying() || !susceptible) return;

    final was = integrity;
    final amount = damage / 50 / _integrity_boost;
    integrity -= amount;
    if (integrity < 0) integrity = 0;
    if (integrity == 0 && was > 0.5) {
      integrity = 0.15;
      _hint = _SoundHint.danger;
      sendMessage(Rumble(duration: 0.2));
    } else if (integrity == 0) {
      on_destroyed();
    } else {
      _update_sound_hint();
      if (amount >= 0.1) sendMessage(Rumble(duration: 0.1));
    }
  }

  void on_destroyed() {
    if (invincible || is_dead_or_dying() || !susceptible) return;

    _state_time = 0;
    state = PlayerState.exploding;
    audio.play(Sound.explosion);
    add(explosions.spawn(this));
    _shield.removeFromParent();
    sendMessage(Rumble(duration: 0.5));
  }

  @override
  void onMount() {
    super.onMount();

    fake_height = 50;

    if (dev || cheat) {
      onKey('<Delete>', () => on_destroyed());
      onKey('<Insert>', () {
        for (final it in stage.children) {
          if (it case EnemyHitPoints it) it.on_destroyed();
        }
        sendMessage(ShowInfoText(text: 'Destroy all enemies', title: 'Cheat'));
      });
      onKey(']', () {
        on_collect_extra(ExtraId.integrity_boost);
        on_collect_extra(ExtraId.shield_boost);
        on_collect_extra(ExtraId.cooldown_boost);
        sendMessage(ShowInfoText(text: 'Boost Stats', title: 'Cheat'));
      });
      onKey('{', () {
        integrity = 1;
        _shield.shield.recharge(1);
        sendMessage(ShowInfoText(text: 'Recharge', title: 'Cheat'));
      });
      onKey('}', () {
        invincible = !invincible;
        sendMessage(ShowInfoText(text: 'Invincible: $invincible', title: 'Cheat'));
      });
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _update_sound(dt);

    switch (state) {
      case PlayerState.incoming:
        _on_incoming(dt);
        break;

      case PlayerState.playing:
        if (stage.phase == GamePhase.transition) state = PlayerState.leaving;
        update_strafe(dt);
        break;

      case PlayerState.exploding:
        _on_exploding(dt);
        break;

      case PlayerState.destroyed:
        break;

      case PlayerState.leaving:
        rot_z += 0.1;
        position.add(_leave_speed * dt);
        _leave_speed.add(_leave_speed * dt / 1.1);
        if (position.x > 900) removeFromParent();
        break;
    }
  }

  final _leave_speed = Vector2(100, -25);
  double _state_time = 0;

  void _on_incoming(double dt) {
    _state_time += dt * 2 / 3;
    if (_state_time >= 1) {
      _state_time = 1;
      state = PlayerState.playing;
      sendMessage(PlayerReady());
    }

    final i = Curves.easeOut.transform(_state_time);
    position.setValues(-50 + 150 * i, 280 + 50 - 50 * i);
  }

  void _on_exploding(double dt) {
    _state_time = min(2, _state_time + dt);
    if (_state_time >= 2) {
      state = PlayerState.destroyed;
      removeFromParent();
      sendMessage(PlayerDestroyed());
    } else if (_state_time > 1) {
      if (isVisible) audio.play(Sound.explosion_hollow);
      isVisible = false;
    } else {
      opacity = 1 - _state_time;
      rot_x += 0.01;
      rot_y -= 0.01;
      rot_z += 0.03;
      position.x += 100 * dt;
      position.y += 50 * dt;

      if ((_state_time % 0.01) < dt) {
        decals.spawn3d(Decal.smoke, this, pos_range: 8, vel_range: 32);
      }
      fake_height = 50 * (1 - _state_time).clamp(0, 1);
    }
  }

  @override
  void set_strafe(double tilt, double move_offset) {
    super.set_strafe(tilt, move_offset);
    rot_x = tilt;
    position.setValues(100 + move_offset / 4, 280 + move_offset);
  }
}

mixin _CreateEntityOnLoad on VoxelEntity, HasContext, HasTraits, Player, Target {
  static const _size = 80.0;

  late final DeflectorShield _shield;

  late final weapons = added(WeaponSystem(this));

  @override
  void onRemove() {
    super.onRemove();
    dispose_sprite();
  }

  @override
  Future onLoad() async {
    // set_vox_source('interstellar_runner.vx', blurred_argb32: [0xffff3200]);
    set_sprite_source(atlas.sprite('entities/ZaxxonPlayer-15.png'), 15);

    shadows.add(create_linked_shadow());

    super.onLoad();

    addTrait(weapons);

    force_render = true;

    rot_x = -0.95;
    rot_y = 1.8;
    rot_z = -0.2;
    scale_x = 1.2;
    scale_y = 2.2;
    scale_z = 1.2;

    size.setAll(_size);
    position.setValues(100, 280);

    add(CircleHitbox(
      radius: _size * 0.2,
      position: Vector2(-_size * 0.15, _size * 0.02),
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
      isSolid: true,
    )..anchor_to_parent());

    add(CircleHitbox(
      radius: _size * 0.075,
      position: Vector2(_size * 0.175, -_size * 0.05),
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
      isSolid: true,
    )..anchor_to_parent());

    _shield = DeflectorShield(this, source_size: size * 1.25);
    _shield.addTrait(Friendly());
    add(_shield);
    addTrait(_shield);
  }
}

mixin _CollectExtras on Player, _CreateEntityOnLoad {
  double _integrity_boost = 1;

  double _hint_time = 0;

  var _hint = _SoundHint.none;

  @override
  double integrity = 1;

  @override
  double get integrity_boost => _integrity_boost;

  @override
  double get shield_boost => _shield.shield.shield_boost;

  @override
  double get cooldown_boost => weapons.cooldown_boost;

  @override
  void on_collect_extra(ExtraId which) {
    if (is_dead_or_dying()) return;

    switch (which) {
      //
      // utility

      case ExtraId.cooldown:
        info('Secondary Cooldown', hud: true);
        weapons.on_secondary_cooldown(0.5);

      case ExtraId.cooldown_boost:
        info('Cooldown Boost', hud: true);
        weapons.on_cooldown_boost();

      case ExtraId.integrity:
        info('Integrity Repair', hud: true);
        integrity = min(1, integrity + 0.25);
        _update_sound_hint();

      case ExtraId.integrity_boost:
        info('Integrity Boost', hud: true);
        _integrity_boost = min(2, _integrity_boost + 0.1);
        _update_sound_hint();

      case ExtraId.shield:
        info('Shield Repair', hud: true);
        onTraits<DeflectorShield>((it) => it.shield.recharge(0.25));

      case ExtraId.shield_boost:
        info('Shield Boost', hud: true);
        onTraits<DeflectorShield>((it) => it.on_shield_boost());

      // primary weapons

      case ExtraId.acid_blast:
        final upgrade = weapons.switch_primary_to(AcidBlaster);
        info('Acid Blast', title: upgrade ? 'Primary Weapon' : null, hud: true);

      case ExtraId.ion_pulse:
        final upgrade = weapons.switch_primary_to(IonPulseGun);
        info('Ion Pulse', title: upgrade ? 'Primary Weapon' : null, hud: true);

      case ExtraId.phosphor_swirl:
        final upgrade = weapons.switch_primary_to(SwirlGun);
        info('Phosphor Swirl', title: upgrade ? 'Primary Weapon' : null, hud: true);

      case ExtraId.triple_plasma:
        final upgrade = weapons.switch_primary_to(PlasmaGun);
        info('Triple Plasma', title: upgrade ? 'Primary Weapon' : null, hud: true);

      case ExtraId.yin_yang:
        final upgrade = weapons.switch_primary_to(YinYangGun);
        info('Yin Yang', title: upgrade ? 'Primary Weapon' : null, hud: true);

      // secondary weapons

      case ExtraId.cluster_bomb:
        info('Cluster Bomb', title: 'Secondary Weapon', hud: true);
        weapons.switch_secondary_to(ClusterBombCannon);

      case ExtraId.nuke_missile:
        info('Nuke Missile', title: 'Secondary Weapon', hud: true);
        weapons.switch_secondary_to(NukeMissileLauncher);

      case ExtraId.plasma_ring:
        info('Plasma Ring', title: 'Secondary Weapon', hud: true);
        weapons.switch_secondary_to(PlasmaEmitter);

      case ExtraId.smart_bomb:
        info('Smart Bomb', title: 'Secondary Weapon', hud: true);
        weapons.switch_secondary_to(SmartBomb);
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
}

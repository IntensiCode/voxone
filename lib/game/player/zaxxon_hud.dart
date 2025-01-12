import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/player/weapon_system.dart';
import 'package:voxone/game/shared/energy_shield.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/mutable.dart';

class ZaxxonHud extends PositionComponent with HasContext, HasPaint {
  ZaxxonHud(this._player) {
    add(BitmapText(text: 'SHIELD', position: Vector2(16, 16))..renderSnapshot = true);
    add(BitmapText(text: 'INTEGRITY', position: Vector2(16, 32))..renderSnapshot = true);
    add(_cooldown = BitmapText(text: 'COOLDOWN', position: Vector2(16, 48))..renderSnapshot = true);

    add(BitmapText(text: 'PRIMARY', position: Vector2(192 + 32, 16))..renderSnapshot = true);
    add(BitmapText(text: 'SECONDARY', position: Vector2(192 * 2, 16))..renderSnapshot = true);
  }

  final Player _player;
  late EnergyShield _shield;
  late WeaponSystem _weapons;

  late BitmapText _cooldown;
  BitmapText? _primary;
  BitmapText? _secondary;
  SpriteComponent? _primary_weapon;
  SpriteComponent? _secondary_weapon;

  @override
  void onMount() {
    super.onMount();
    _shield = _player.singleTrait<EnergyShield>();
    _weapons = _player.singleTrait<WeaponSystem>();

    scale.setAll(0);
    add(ScaleEffect.to(Vector2(1, 1), CurvedEffectController(0.2, Curves.easeIn)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cooldown.isVisible = _weapons.secondary_weapon != null;

    final primary = _weapons.primary_weapon.display_name;
    if (_primary?.text != primary) {
      _primary?.removeFromParent();
      add(_primary = BitmapText(text: primary, position: Vector2(192 + 32, 32))..renderSnapshot = true);
      _primary_weapon ??= added(SpriteComponent()..position = Vector2(192 + 32 - 26, 18));
      _primary_weapon?.sprite = _weapons.primary_weapon.icon;
    }

    final secondary = _weapons.secondary_weapon?.display_name ?? 'N/A';
    if (_secondary?.text != secondary) {
      _secondary?.removeFromParent();
      add(_secondary = BitmapText(text: secondary, position: Vector2(192 * 2, 32))..renderSnapshot = true);
      _secondary_weapon ??= added(SpriteComponent()..position = Vector2(192 * 2 - 26, 18));
      _secondary_weapon?.sprite = _weapons.secondary_weapon?.icon;
      if (_weapons.secondary_weapon == null) {
        _secondary_weapon?.removeFromParent();
      } else if (_secondary_weapon?.parent == null) {
        add(_secondary_weapon!);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    _draw_indicator(canvas, _shield.energy, 0);
    _draw_indicator(canvas, _player.integrity, 16);
    if (_weapons.secondary_weapon != null) {
      _draw_indicator(canvas, (1 - (_weapons.secondary_cooldown ?? 1)), 32);
    }
  }

  void _draw_indicator(Canvas canvas, double value, double offset_y) {
    if (value <= 0) return;
    paint.color = switch (value) {
      > .6 => _good,
      > .5 => _damaged,
      > .2 => _danger,
      _ => _critical,
    };
    _rect.left = 16;
    _rect.top = 26 + offset_y;
    _rect.right = 16 + value * 100;
    _rect.bottom = 30 + offset_y;
    canvas.drawRect(_rect, paint);
  }

  final _rect = MutRect(0, 0, 0, 0);

  final _good = white;
  final _damaged = const Color(0xFFf0f060);
  final _danger = const Color(0xFFf0a060);
  final _critical = const Color(0xF0ff4040);
}

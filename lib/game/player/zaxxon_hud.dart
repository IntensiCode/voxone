import 'dart:ui';

import 'package:flame/components.dart';
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
    add(_shield = BitmapText(text: 'SHIELD', position: Vector2(16, 16)));
    add(_integrity = BitmapText(text: 'INTEGRITY', position: Vector2(16, 32)));
    add(_cooldown = BitmapText(text: 'COOLDOWN', position: Vector2(16, 48)));

    add(BitmapText(text: 'PRIMARY', position: Vector2(192 + 32, 16)));
    add(BitmapText(text: 'SECONDARY', position: Vector2(192 * 2, 16)));

    this.fadeInDeep();
  }

  final Player _player;
  late EnergyShield _player_shield;
  late WeaponSystem _weapons;

  late BitmapText _shield;
  late BitmapText _integrity;
  late BitmapText _cooldown;

  double? _shield_boost;
  double? _integrity_boost;
  double? _cooldown_boost;

  BitmapText? _primary;
  BitmapText? _secondary;
  SpriteComponent? _primary_weapon;
  SpriteComponent? _secondary_weapon;

  @override
  void onMount() {
    super.onMount();
    _player_shield = _player.singleTrait<EnergyShield>();
    _weapons = _player.singleTrait<WeaponSystem>();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cooldown.isVisible = _weapons.secondary_weapon != null;

    final i = _player.integrity_boost;
    if (i != _integrity_boost) {
      _integrity_boost = i;
      _integrity.change_text_in_place('INTEGRITY:${i.toStringAsFixed(2)}');
      _integrity.fadeInDeep();
    }

    final s = _player.shield_boost;
    if (s != _shield_boost) {
      _shield_boost = s;
      _shield.change_text_in_place('SHIELD:${s.toStringAsFixed(2)}');
      _shield.fadeInDeep();
    }

    final c = _player.cooldown_boost;
    if (c != _cooldown_boost) {
      _cooldown_boost = c;
      _cooldown.change_text_in_place('COOLDOWN:${c.toStringAsFixed(2)}');
      _cooldown.fadeInDeep();
    }

    final primary = _weapons.primary_weapon.display_name;
    if (_primary?.text != primary) {
      _primary?.removeFromParent();
      add(_primary = BitmapText(text: primary, position: Vector2(192 + 32, 32))..renderSnapshot = true);
      _primary_weapon ??= added(SpriteComponent()..position = Vector2(192 + 32 - 26, 18));
      _primary_weapon?.sprite = _weapons.primary_weapon.icon;
      _primary?.fadeInDeep();
      _primary_weapon?.fadeInDeep();
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
      _secondary?.fadeInDeep();
      _secondary_weapon?.fadeInDeep();
    }
  }

  @override
  void render(Canvas canvas) {
    _draw_indicator(canvas, _player_shield.energy, 0);
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

    // FIXME why does this.opacity not work? ‾\_('')_/‾
    paint.opacity = _cooldown.opacity;

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

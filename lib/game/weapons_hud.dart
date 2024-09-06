import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/player/base_weapon.dart';
import 'package:voxone/game/player/player_state.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/fonts.dart';
import 'package:voxone/util/functions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class WeaponsHud extends PositionComponent with AutoDispose, HasPaint {
  WeaponsHud(this._sprites32);

  final SpriteSheet _sprites32;

  late final Sprite _slot;

  final _render_pos = Vector2.zero();

  double _blink_time = 0;

  @override
  FutureOr<void> onLoad() async {
    _slot = await sprite('weapon_slot.png');
    paint.opacity = 0;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (paint.opacity < 1 && player.state == PlayerState.playing) {
      paint.opacity += min(1 - paint.opacity, dt * 4);
    }
    if (paint.opacity > 0 && player.state != PlayerState.playing) {
      paint.opacity -= min(paint.opacity, dt * 4);
    }
    _blink_time += dt;
    if (_blink_time > 1) _blink_time -= 1;
  }

  // TODO snapshot

  final _armory = <BaseWeapon>[];

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_armory.isEmpty) {
      _armory.addAll(model.weapons.weapons.values);
      _armory.add(model.grenades);
    }

    if (paint.opacity == 0) return;
    // if (player.state != PlayerState.playing) return;

    _render_pos.x = 0;
    for (final it in _armory) {
      final grenades = it == model.grenades;
      if (grenades) _render_pos.x += 4;

      final show_blink = it != player.active_weapon || _blink_time < 0.8;
      tiny_font.paint = paint;
      final label = grenades ? '0' : (it.type.index + 1).toString();
      tiny_font.drawStringAligned(canvas, _render_pos.x + 16, 212, label, Anchor.center);

      if (it.ammo != 0) {
        _render_pos.y = 240 - 26;
        _slot.render(canvas, position: _render_pos, overridePaint: paint);
      }

      _render_pos.y = 240 - 41;
      if (show_blink) {
        final sprite = grenades ? _sprites32.getSprite(16, 2) : _sprites32.getSprite(17, it.type.index);
        sprite.render(canvas, position: _render_pos, overridePaint: paint);
      }

      final x = _render_pos.x + 16;
      final y = _render_pos.y + 36;
      final ammo = it.ammo == -1 ? '\u0080' : it.ammo.toString();
      tiny_font.paint = paint;
      tiny_font.drawStringAligned(canvas, x, y, ammo, Anchor.center);

      if (it.ammo == 0) {
        _render_pos.y = 240 - 26;
        _slot.render(canvas, position: _render_pos, overridePaint: paint);
      }

      _render_pos.x += 32;
    }
  }
}

import 'dart:async';

import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/util/effects.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/on_message.dart';

class InfoOverlay extends GameScriptComponent {
  InfoOverlay() {
    add(_info = _InfoOverlay());
    add(_hud = _InfoOverlay(pos_y: 480 - 32, quick: true));
  }

  late _InfoOverlay _info;
  late _InfoOverlay _hud;

  @override
  void onMount() {
    super.onMount();
    onMessage<ShowInfoText>((it) {
      final target = it.hud_align ? _hud : _info;
      target.pipe.add(it);

      if (it.text == 'Enemy Wave Incoming') {
        audio.play_one_shot_sample('voice/enemy_wave_incoming.ogg');
      } else if (it.text == 'Minefield Ahead') {
        audio.play_one_shot_sample('voice/minefield_ahead.ogg');
      } else if (it.text == 'Planetary Fleet Arriving') {
        audio.play_one_shot_sample('voice/planetary_fleet_arriving.ogg');
      } else if (it.text == 'Capital Ship Approaching') {
        audio.play_one_shot_sample('voice/capital_ship_approaching.ogg');
      } else if (it.title == 'Primary Weapon') {
        audio.play_one_shot_sample('voice/primary_weapon_upgrade.ogg', volume_factor: 2);
      } else if (it.title == 'Secondary Weapon') {
        audio.play_one_shot_sample('voice/secondary_weapon_upgrade.ogg', volume_factor: 2);
      }
    });
  }
}

class _InfoOverlay extends GameScriptComponent {
  _InfoOverlay({this.pos_y = game_height / 2, this.quick = false});

  final pipe = <ShowInfoText>[];

  final double pos_y;
  final bool quick;

  Future? _active;

  @override
  void update(double dt) {
    super.update(dt);

    if (_active != null || pipe.isEmpty) return;

    final it = pipe.first;

    clearScript();
    removeAll(children);

    Component? title_text;
    late Component text;

    after(0.0, () {
      final t = it.title;
      if (t != null) title_text = textXY(t, game_width / 2, pos_y - 15, scale: 2);
      title_text?.fadeInDeep();
      text = textXY(it.text, game_width / 2, pos_y + 5);
      text.fadeInDeep();
    });
    if (pipe.length > 3) {
      after(0.4, () => text.fadeOutDeep());
      after(0.0, () => title_text?.fadeOutDeep());
      after(0.4, () => it.when_done?.call());
    } else {
      after(quick ? 0.2 : 0.4, () {
        if (it.blink_text) text.add(BlinkEffect(on: 0.35, off: 0.15));
      });
      after(quick ? 0.9 : 1.8, () => text.removeAll(text.children)); // remove blink?
      if (pipe.length == 1) {
        after(quick ? 0.0 : 1.0, () => text.fadeOutDeep());
        after(0.0, () => title_text?.fadeOutDeep());
        after(quick ? 0.2 : 0.5, () => it.when_done?.call());
      } else {
        after(0.0, () => it.when_done?.call());
      }
    }

    final active = _active = executeScript();
    _active?.then((_) {
      pipe.removeAt(0);
      if (_active == active) _active = null;
    });
  }
}

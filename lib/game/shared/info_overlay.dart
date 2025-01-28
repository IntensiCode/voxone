import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/effects.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/on_message.dart';

class InfoOverlay extends GameScriptComponent {
  InfoOverlay(this._time_scale) {
    add(_info = _InfoOverlay(quick: dev));
    add(_hud = _InfoOverlay(pos_y: 480 - 32, quick: true));
    add(_cheat = _InfoOverlay(pos_y: 480 - 16, quick: true));
    priority = 9000;
  }

  final double Function() _time_scale;

  late _InfoOverlay _info;
  late _InfoOverlay _hud;
  late _InfoOverlay _cheat;

  @override
  void onMount() {
    super.onMount();
    onMessage<ShowInfoText>((it) {
      if (it.title == 'Cheat') {
        _cheat.pipe.add(it..title = null);
      } else {
        final target = it.hud_align ? _hud : _info;
        target.pipe.add(it);
      }
    });
  }

  @override
  void updateTree(double dt) {
    super.updateTree(dt / _time_scale());
  }
}

class _InfoOverlay extends GameScriptComponent {
  _InfoOverlay({this.pos_y = game_height / 2, this.quick = false});

  final pipe = <ShowInfoText>[];

  final double pos_y;
  final bool quick;

  Future? _active;

  late final BitmapText _title_text;
  late final BitmapText _text;

  @override
  onLoad() {
    _title_text = added(textXY('', game_width / 2, pos_y - 15, scale: 2)..isVisible = false);
    _text = added(textXY('', game_width / 2, pos_y + 5)..isVisible = false);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_active != null || pipe.isEmpty) return;

    final it = pipe.first;

    _play_sound(it);

    clearScript();

    after(0.0, () {
      _title_text.isVisible = it.title != null;
      _title_text.change_text_in_place(it.title ?? '');
      if (it.title != null) _title_text.fadeInDeep();

      _text.isVisible = true;
      _text.change_text_in_place(it.text);
      _text.fadeInDeep();
    });
    if (kReleaseMode && it.stay_longer) after(2, () {});
    if (pipe.length > 3) {
      after(0.4, () => _text.fadeOutDeep(and_remove: false));
      after(0.0, () {
        if (it.title != null) _title_text.fadeOutDeep(and_remove: false);
      });
      after(0.4, () => it.when_done?.call());
    } else {
      after(quick ? 0.2 : 0.4, () {
        if (it.blink_text) _text.add(BlinkEffect(on: 0.35, off: 0.15));
      });
      after(quick ? 0.9 : 1.8, () => _text.removeAll(_text.children)); // remove blink?
      if (pipe.length == 1) {
        after(quick ? 0.0 : 1.0, () => _text.fadeOutDeep(and_remove: false));
        after(0.0, () {
          if (it.title != null) _title_text.fadeOutDeep(and_remove: false);
        });
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

  void _play_sound(ShowInfoText it) {
    if (it.text == 'Enemy Wave Incoming') {
      audio.play_one_shot_sample('voice/enemy_wave_incoming.ogg', volume_factor: 2);
    } else if (it.text == 'Minefield Ahead') {
      audio.play_one_shot_sample('voice/minefield_ahead.ogg', volume_factor: 2);
    } else if (it.text == 'Planetary Fleet Arriving') {
      audio.play_one_shot_sample('voice/planetary_fleet_arriving.ogg', volume_factor: 2);
    } else if (it.text == 'Crossing Asteroid Belt') {
      audio.play_one_shot_sample('voice/crossing_asteroid_belt.ogg', volume_factor: 2);
    } else if (it.text == 'Capital Ship Approaching') {
      audio.play_one_shot_sample('voice/capital_ship_approaching.ogg', volume_factor: 2);
    } else if (it.title == 'Primary Weapon') {
      audio.play_one_shot_sample('voice/primary_weapon_upgrade.ogg', volume_factor: 2);
    } else if (it.title == 'Secondary Weapon') {
      audio.play_one_shot_sample('voice/secondary_weapon_upgrade.ogg', volume_factor: 2);
    } else if (it.title == 'Stage Complete') {
      audio.play_one_shot_sample('voice/stage_complete.ogg', volume_factor: 2);
    } else if (it.title == 'Game Over') {
      audio.play(Sound.game_over, volume_factor: 2);
    }
  }
}

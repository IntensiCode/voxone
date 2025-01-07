import 'dart:async';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/util/effects.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/on_message.dart';

class InfoOverlay extends GameScriptComponent {
  InfoOverlay() {
    add(_info = _InfoOverlay());
    add(_hud = _InfoOverlay(pos_y: 32, stay_time: 0.2));
  }

  late _InfoOverlay _info;
  late _InfoOverlay _hud;

  @override
  void onMount() {
    super.onMount();
    onMessage<ShowInfoText>((it) {
      final target = it.hud_align ? _hud : _info;
      target.pipe.add(it);
    });
  }
}

class _InfoOverlay extends GameScriptComponent {
  _InfoOverlay({this.pos_y = game_height / 2, this.stay_time = 0.4});

  final pipe = <ShowInfoText>[];

  final double pos_y;
  final double stay_time;

  StreamSubscription? _active;

  @override
  void update(double dt) {
    super.update(dt);

    if (_active != null || pipe.isEmpty) return;

    final it = pipe.first;

    clearScript();
    removeAll(children);

    Component? title_text;
    late Component text;

    at(0.0, () {
      final t = it.title;
      if (t != null) title_text = textXY(t, game_width / 2, pos_y - 15, scale: 2);
      title_text?.fadeInDeep();
      text = textXY(it.text, game_width / 2, pos_y + 5);
      text.fadeInDeep();
    });
    at(stay_time, () {
      if (it.blink_text) text.add(BlinkEffect(on: 0.35, off: 0.15));
    });
    at(1.8, () => text.removeAll(text.children)); // remove blink?
    if (pipe.length == 1) {
      at(1.0, () => text.fadeOutDeep());
      at(0.0, () => title_text?.fadeOutDeep());
      at(0.5, () => it.when_done?.call());
    } else {
      at(0.0, () => it.when_done?.call());
    }

    final active = _active = executeScript();
    _active?.onDone(() {
      pipe.removeAt(0);
      if (_active == active) _active = null;
    });
  }
}

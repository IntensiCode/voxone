import 'package:dart_minilog/dart_minilog.dart';
import 'package:flutter/services.dart';
import 'package:gamepads/gamepads.dart';
import 'package:voxone/input/game_pads.dart';
import 'package:voxone/util/auto_dispose.dart';

mixin HasGamePads {
  final detected_game_pads = <String, String>{};

  Future? _rescan_game_pads;

  void _rescan_changed_game_pads() => _rescan_game_pads ??= Gamepads.list().then((it) {
        detected_game_pads.clear();
        for (final gp in it) {
          detected_game_pads[gp.id] = gp.name;
        }
        logInfo('detected game pads: $detected_game_pads');
        _rescan_game_pads = null;
      });

  Disposable observe_gamepads() {
    _rescan_changed_game_pads();

    final stream = Gamepads.events.listen((event) {
      if (!detected_game_pads.containsKey(event.gamepadId)) {
        _rescan_changed_game_pads();
      }

      final it = int.parse(event.key);
      if (event.type == KeyType.button) {
        onSnoop(SnoopType.button, 200 + it, event.value);
        final gpc = hw_mapping[200 + it];
        if (gpc != null) onGamePad(gpc, event.value);
      } else if (event.type == KeyType.analog) {
        onSnoop(SnoopType.axis, 100 + it, event.value / 32767);
        final gpc = hw_mapping[100 + it];
        if (gpc != null) onGamePad(gpc, event.value / 32767);
      }
    });
    return Disposable.wrap(() => stream.cancel());
  }

  void tick_game_pads() {}

  void rumble([int duration = 100]) {
    HapticFeedback.vibrate();
    HapticFeedback.heavyImpact();
  }
}

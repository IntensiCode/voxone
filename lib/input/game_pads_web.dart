import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:supercharged/supercharged.dart';
import 'package:voxone/input/game_pads.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:web/web.dart';

mixin HasGamePads {
  final detected_game_pads = <String, String>{};

  static final _buttons = <(String, int), bool>{}; // .values.associate((it) => MapEntry(it, false));
  static final _axes = <(String, int), double>{};

  void tick_game_pads() {
    final it = window.navigator.getGamepads().toDart;
    if (it.isEmpty) return;
    if (it.count((e) => e != null) != detected_game_pads.length) {
      logInfo('clear detected game pads');
      detected_game_pads.clear();
    }
    final was = detected_game_pads.length;
    for (final gp in it) {
      if (gp == null) continue;
      detected_game_pads[gp.id] = gp.id;
      _tick_game_pad(gp);
    }
    if (was != detected_game_pads.length) {
      logInfo('detected game pads: $detected_game_pads');
    }
  }

  void _tick_game_pad(Gamepad gp) {
    final buttons = gp.buttons.toDart;
    for (var i = 0; i < buttons.length; i++) {
      final button = buttons[i];
      if (_buttons[(gp.id, i)] == button.pressed) continue;
      _buttons[(gp.id, i)] = button.pressed;
      onSnoop(SnoopType.button, 200 + i, button.value);
      final gpc = hw_mapping[200 + i];
      if (gpc != null) onGamePad(gpc, button.value);
    }

    final axes = gp.axes.toDart;
    for (final (i, value) in axes.indexed) {
      final now = value.toDartDouble;
      if (now == _axes[(gp.id, i)]) continue;
      _axes[(gp.id, i)] = now;
      onSnoop(SnoopType.axis, 100 + i, now);
      final gpc = hw_mapping[100 + i];
      if (gpc != null) onGamePad(gpc, now);
    }
  }

  Disposable observe_gamepads() {
    final it = window.navigator.getGamepads().toDart;
    for (final gp in it) {
      if (gp == null) continue;
      detected_game_pads[gp.id] = gp.id;
    }
    logInfo('detected game pads: $detected_game_pads');
    return Disposable.disposed;
  }

  void rumble([int duration = 100]) {
    final it = window.navigator.getGamepads().toDart;
    if (it.isEmpty) return;
    final gp = it[0];
    if (gp == null) return;
    final va = gp.getProperty('vibrationActuator'.toJS);
    if (va != null) _rumble_va(va, duration);
  }

  void _rumble_va(JSAny va, int duration) {
    final obj = JSObject.fromInteropObject(va);
    final data = JSObject();
    data.setProperty('duration'.toJS, duration.toJS);
    data.setProperty('startDelay'.toJS, 0.toJS);
    data.setProperty('strongMagnitude'.toJS, 1.toJS);
    data.setProperty('weakMagnitude'.toJS, 1.toJS);
    obj.callMethod('playEffect'.toJS, 'dual-rumble'.toJS, data);
  }
}

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:supercharged/supercharged.dart';
import 'package:voxone/input/game_keys.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:web/web.dart';

enum _GamePadButton {
  a(GameKey.a_button),
  b(GameKey.b_button),
  x(GameKey.x_button),
  y(GameKey.y_button),
  left_bumper(GameKey.soft1),
  right_bumper(GameKey.soft2),
  left_trigger,
  right_trigger,
  select(GameKey.select),
  start(GameKey.start),
  left_stick,
  right_stick,
  dpad_up(GameKey.up),
  dpad_down(GameKey.down),
  dpad_left(GameKey.left),
  dpad_right(GameKey.right),
  ;

  final GameKey? key;

  const _GamePadButton([this.key]);
}

enum _GamePadAxis {
  left_stick_x,
  left_stick_y,
  right_stick_x,
  right_stick_y,
}

mixin HasGamePads {
  late void Function(GameKey) onGamePadPressed;
  late void Function(GameKey) onGamePadReleased;

  static final _buttons = _GamePadButton.values.associate((it) => MapEntry(it, false));
  static final _axes = _GamePadAxis.values.associate((it) => MapEntry(it, 0.0));

  void tick_game_pads() {
    final it = window.navigator.getGamepads().toDart;
    if (it.isEmpty) return;
    final gp = it[0];
    if (gp == null) return;

    final buttons = gp.buttons.toDart;
    for (var i = 0; i < buttons.length; i++) {
      final button = buttons[i];
      if (i >= _GamePadButton.values.length) break;

      final gpb = _GamePadButton.values[i];
      if (_buttons[gpb] == button.pressed) continue;
      _buttons[gpb] = button.pressed;

      final key = gpb.key;
      if (key == null) continue;

      if (button.pressed) {
        onGamePadPressed(key);
      } else {
        onGamePadReleased(key);
      }
    }

    final axes = gp.axes.toDart;
    for (final it in _GamePadAxis.values) {
      final now = axes[it.index].toDartDouble;
      if (now == _axes[it]) continue;
      _axes[it] = now;

      if (it == _GamePadAxis.left_stick_x || it == _GamePadAxis.right_stick_x) {
        if (now < -0.8) {
          onGamePadPressed(GameKey.left);
        } else if (now > 0.8) {
          onGamePadPressed(GameKey.right);
        } else {
          onGamePadReleased(GameKey.left);
          onGamePadReleased(GameKey.right);
        }
      }
      if (it == _GamePadAxis.left_stick_y || it == _GamePadAxis.right_stick_y) {
        if (now < -0.8) {
          onGamePadPressed(GameKey.up);
        } else if (now > 0.8) {
          onGamePadPressed(GameKey.down);
        } else {
          onGamePadReleased(GameKey.up);
          onGamePadReleased(GameKey.down);
        }
      }
    }
  }

  Disposable observe_gamepads() => Disposable.disposed;

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

import 'dart:js_interop';

import 'package:supercharged/supercharged.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/game_keys.dart';
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

mixin HasGamePads {
  abstract void Function(GameKey) onPressed;
  abstract void Function(GameKey) onReleased;

  static final _state = _GamePadButton.values.associate((it) => MapEntry(it, false));

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
      if (_state[gpb] == button.pressed) continue;
      _state[gpb] = button.pressed;

      final key = gpb.key;
      if (key == null) continue;

      if (button.pressed) {
        onPressed(key);
      } else {
        onReleased(key);
      }
    }
  }

  Disposable observe_gamepads() => Disposable.disposed;
}

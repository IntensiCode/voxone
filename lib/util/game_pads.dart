import 'package:dart_minilog/dart_minilog.dart';
import 'package:gamepads/gamepads.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/game_keys.dart';

enum _GamePadButton {
  a(GameKey.fire1),
  b(GameKey.fire2),
  x(GameKey.use),
  y(GameKey.inventory),
  left_bumper(GameKey.soft1),
  right_bumper(GameKey.soft2),
  // left_trigger,
  // right_trigger,
  select(GameKey.select),
  start(GameKey.start),
  invalid0,
  left_stick,
  right_stick,
  // dpad_up(GameKey.up),
  // dpad_down(GameKey.down),
  // dpad_left(GameKey.left),
  // dpad_right(GameKey.right),
  ;

  final GameKey? key;

  const _GamePadButton([this.key]);
}

mixin HasGamePads {
  abstract void Function(GameKey) onPressed;
  abstract void Function(GameKey) onReleased;

  Disposable observe_gamepads() {
    final stream = Gamepads.events.listen((event) {
      if (event.type == KeyType.button) {
        try {
          final it = int.parse(event.key);
          if (it >= _GamePadButton.values.length) return;
          final gpb = _GamePadButton.values[it];
          final key = gpb.key;
          if (key != null) {
            if (event.value == 1) {
              onPressed(key);
            } else {
              onReleased(key);
            }
          }
        } catch (e, st) {
          logError(e, st);
        }
      } else if (event.type == KeyType.analog) {
        if (event.key == "6") {
          if (event.value < -0.5) {
            onPressed(GameKey.left);
          } else if (event.value > 0.5) {
            onPressed(GameKey.right);
          } else {
            onReleased(GameKey.left);
            onReleased(GameKey.right);
          }
        } else if (event.key == "7") {
          if (event.value < -0.5) {
            onPressed(GameKey.up);
          } else if (event.value > 0.5) {
            onPressed(GameKey.down);
          } else {
            onReleased(GameKey.up);
            onReleased(GameKey.down);
          }
        }
      } else {
        logInfo("Gamepads event: $event key: ${event.key} type: ${event.type} value: ${event.value}");
      }
    });
    return Disposable.wrap(() => stream.cancel());
  }

  void tick_game_pads() {}
}

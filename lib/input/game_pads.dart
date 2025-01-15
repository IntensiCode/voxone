import 'package:dart_minilog/dart_minilog.dart';
import 'package:gamepads/gamepads.dart';
import 'package:voxone/input/game_keys.dart';
import 'package:voxone/util/auto_dispose.dart';

enum _GamePadButton {
  a(GameKey.a_button),
  b(GameKey.b_button),
  x(GameKey.x_button),
  y(GameKey.y_button),
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

const _analog_sensitivity = 8192;

mixin HasGamePads {
  late void Function(GameKey) onGamePadPressed;
  late void Function(GameKey) onGamePadReleased;

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
              onGamePadPressed(key);
            } else {
              onGamePadReleased(key);
            }
          }
        } catch (e, st) {
          logError(e, st);
        }
      } else if (event.type == KeyType.analog) {
        if (event.key == "6" || event.key == "0" || event.key == "3") {
          if (event.value < -_analog_sensitivity) {
            onGamePadPressed(GameKey.left);
          } else if (event.value > _analog_sensitivity) {
            onGamePadPressed(GameKey.right);
          } else {
            onGamePadReleased(GameKey.left);
            onGamePadReleased(GameKey.right);
          }
        } else if (event.key == "7" || event.key == "1" || event.key == "4") {
          if (event.value < -_analog_sensitivity) {
            onGamePadPressed(GameKey.up);
          } else if (event.value > _analog_sensitivity) {
            onGamePadPressed(GameKey.down);
          } else {
            onGamePadReleased(GameKey.up);
            onGamePadReleased(GameKey.down);
          }
        }
      } else {
        logInfo("Gamepads event: $event key: ${event.key} type: ${event.type} value: ${event.value}");
      }
    });
    return Disposable.wrap(() => stream.cancel());
  }

  void tick_game_pads() {}

  void rumble([int duration = 100]) {}
}

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:supercharged/supercharged.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/input/game_keys.dart';
import 'package:voxone/util/auto_dispose.dart';

import 'game_pads.dart' if (dart.library.html) 'game_pads_web.dart';

export 'game_keys.dart';

class Keys extends AutoDisposeComponent with KeyboardHandler, HasGameKeys, HasGamePads {
  static int _instances = 0;

  Keys() {
    logInfo('Keys created');
    _instances++;
    logInfo('Keys instances: $_instances');
  }

  @override
  void onRemove() {
    logInfo('Keys removed');
    _instances--;
    logInfo('Keys instances: $_instances');
  }

  static const _do_not_repeat = {GameKey.a_button, GameKey.b_button, GameKey.soft1, GameKey.soft2};
  static const _repeat_delay_ticks = tps ~/ 4;
  static const _repeat_interval_ticks = tps ~/ 20;

  final _pressed = <GameKey>{};
  final _repeat = <GameKey>{};
  final _repeat_ticks = <GameKey, int>{};

  bool check_and_consume(GameKey key) => _pressed.remove(key);

  bool any(List<GameKey> keys) => keys.count((it) => check_and_consume(it)) > 0;

  bool check(GameKey it) => _pressed.contains(it);

  void consume(GameKey it) => _pressed.remove(it);

  bool get is_some_key_pressed => _pressed.isNotEmpty;

  @override
  void onMount() {
    super.onMount();

    logInfo('Keys mounted');
    if (_instances > 1) logError('More than one Keys instance active');

    onPressed = (it) => _update(it, true);
    onReleased = (it) => _update(it, false);
    autoDispose("gamepads", observe_gamepads());
  }

  @override
  void update(double dt) {
    super.update(dt);
    tick_game_pads();
    _repeat_ticks.updateAll((it, ticks) {
      if (ticks > 0) {
        return ticks - 1;
      } else {
        _pressed.add(it);
        return _repeat_interval_ticks;
      }
    });
  }

  void _update(GameKey it, bool pressed) {
    if (pressed) {
      held[it] = true;
      _pressed.add(it);
      if (!_repeat.contains(it) && !_do_not_repeat.contains(it)) {
        _repeat.add(it);
        _repeat_ticks[it] = _repeat_delay_ticks;
      }
    } else {
      held[it] = false;
      _pressed.remove(it);
      _repeat.remove(it);
      _repeat_ticks.remove(it);
    }
  }
}

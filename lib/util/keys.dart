import 'package:flame/components.dart';
import 'package:supercharged/supercharged.dart';

import '../core/common.dart';
import 'game_keys.dart';

export 'game_keys.dart';

class Keys extends Component with KeyboardHandler, HasGameKeys {
  static const _do_not_repeat = {GameKey.fire1, GameKey.fire2, GameKey.soft1, GameKey.soft2};
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
    onPressed = (it) => _update(it, true);
    onReleased = (it) => _update(it, false);
  }

  @override
  void update(double dt) {
    super.update(dt);
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
      _pressed.add(it);
      if (!_repeat.contains(it) && !_do_not_repeat.contains(it)) {
        _repeat.add(it);
        _repeat_ticks[it] = _repeat_delay_ticks;
      }
    } else {
      _pressed.remove(it);
      _repeat.remove(it);
      _repeat_ticks.remove(it);
    }
  }
}

import 'package:dart_minilog/dart_minilog.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/input/game_keys.dart';
import 'package:voxone/util/auto_dispose.dart';

bool enable_mapping = false;

double analog_sensitivity = 0.8;

enum SnoopType {
  button,
  axis,
}

Disposable snoop_game_pad_input(void Function(SnoopType, int, double) cb) {
  _snoop_raw.add(cb);
  return Disposable.wrap(() => _snoop_raw.remove(cb));
}

Disposable snoop_game_pad({void Function(GameKey)? on_pressed, void Function(GameKey)? on_released}) {
  if (on_pressed != null) _snoop_pressed.add(on_pressed);
  if (on_released != null) _snoop_released.add(on_released);
  return Disposable.wrap(() {
    _snoop_pressed.remove(on_pressed);
    _snoop_released.remove(on_released);
  });
}

final _snoop_raw_clone = <void Function(SnoopType, int, double)>[];

void onSnoop(SnoopType type, int id, double value) {
  _snoop_raw_clone.clear();
  _snoop_raw_clone.addAll(_snoop_raw);
  for (final cb in _snoop_raw_clone) {
    cb(type, id, value);
  }
}

final _snoop_raw = <void Function(SnoopType, int, double)>[];

final _snoop_pressed = <void Function(GameKey)>[];
final _snoop_released = <void Function(GameKey)>[];

void _onGamePadPressed(GameKey it) {
  for (final cb in _snoop_pressed) {
    cb(it);
  }
}

void _onGamePadReleased(GameKey it) {
  for (final cb in _snoop_released) {
    cb(it);
  }
}

void onGamePad(GamePadControl it, double value) {
  final gk = gk_mapping[it];
  if (gk == null) {
    if (dev) logError('no mapping for: $it');
    return;
  }

  if (gk == GameKey.x_axis) {
    if (value < -analog_sensitivity) {
      _onGamePadPressed(GameKey.left);
    } else if (value > analog_sensitivity) {
      _onGamePadPressed(GameKey.right);
    } else {
      _onGamePadReleased(GameKey.left);
      _onGamePadReleased(GameKey.right);
    }
  } else if (gk == GameKey.y_axis) {
    if (value < -analog_sensitivity) {
      _onGamePadPressed(GameKey.up);
    } else if (value > analog_sensitivity) {
      _onGamePadPressed(GameKey.down);
    } else {
      _onGamePadReleased(GameKey.up);
      _onGamePadReleased(GameKey.down);
    }
  } else if (gk == GameKey.l_throttle) {
    // nop for now
  } else if (gk == GameKey.r_throttle) {
    // nop for now
  } else /*buttons*/ {
    if (value == 1.0) {
      _onGamePadPressed(gk);
    } else if (value == 0.0) {
      _onGamePadReleased(gk);
    } else {
      if (dev) logError('unsupported value: $value for $it');
    }
  }
}

const ANALOG_BASE = 100;
const BUTTON_BASE = 200;

final _xbox360_hw_mapping = <int, GamePadControl>{
  100: GamePadControl.analog_left_x,
  101: GamePadControl.analog_left_y,
  102: GamePadControl.throttle_left,
  103: GamePadControl.analog_right_x,
  104: GamePadControl.analog_right_y,
  105: GamePadControl.throttle_right,
  106: GamePadControl.dpad_x,
  107: GamePadControl.dpad_y,
  200: GamePadControl.a,
  201: GamePadControl.b,
  202: GamePadControl.x,
  203: GamePadControl.y,
  204: GamePadControl.left_bumper,
  205: GamePadControl.right_bumper,
  206: GamePadControl.select,
  207: GamePadControl.start,
  209: GamePadControl.left_stick,
  210: GamePadControl.right_stick,
  212: GamePadControl.dpad_up,
  213: GamePadControl.dpad_down,
  214: GamePadControl.dpad_left,
  215: GamePadControl.dpad_right,
};

final _zikway_hw_mapping = <int, GamePadControl>{
  100: GamePadControl.analog_left_x,
  101: GamePadControl.analog_left_y,
  102: GamePadControl.analog_right_x,
  103: GamePadControl.analog_right_y,
  104: GamePadControl.throttle_right,
  105: GamePadControl.throttle_left,
  106: GamePadControl.dpad_x,
  107: GamePadControl.dpad_y,
  200: GamePadControl.a,
  201: GamePadControl.b,
  203: GamePadControl.x,
  204: GamePadControl.y,
  206: GamePadControl.left_bumper,
  207: GamePadControl.right_bumper,
  208: GamePadControl.left_trigger,
  209: GamePadControl.right_trigger,
  210: GamePadControl.select,
  211: GamePadControl.start,
  213: GamePadControl.left_stick,
  214: GamePadControl.right_stick,
};

// a/b and x/y swapped \_('')_/
final _8bitdo_hw_mapping = <int, GamePadControl>{
  100: GamePadControl.analog_left_x,
  101: GamePadControl.analog_left_y,
  102: GamePadControl.analog_right_x,
  103: GamePadControl.analog_right_y,
  104: GamePadControl.throttle_right,
  105: GamePadControl.throttle_left,
  106: GamePadControl.dpad_x,
  107: GamePadControl.dpad_y,
  200: GamePadControl.b,
  201: GamePadControl.a,
  202: GamePadControl.under_right,
  203: GamePadControl.y,
  204: GamePadControl.x,
  205: GamePadControl.under_left,
  206: GamePadControl.left_bumper,
  207: GamePadControl.right_bumper,
  208: GamePadControl.left_trigger,
  209: GamePadControl.right_trigger,
  210: GamePadControl.select,
  211: GamePadControl.start,
  213: GamePadControl.left_stick,
  214: GamePadControl.right_stick,
};

enum GamePadPreset {
  EightBitDoPro2('8BitDo 8BitDo Pro 2', '8BitDo Pro 2'),
  GameSirNovaLite('Zikway HID gamepad', 'GameSir Nova Lite'),
  MicrosoftXbox360('Microsoft X-Box 360 pad', 'Microsoft XBox 360'),
  ;

  final String id;
  final String name;

  const GamePadPreset(this.id, this.name);
}

final known_hw_mappings = <GamePadPreset, Map<int, GamePadControl>>{
  GamePadPreset.EightBitDoPro2: _8bitdo_hw_mapping,
  GamePadPreset.GameSirNovaLite: _zikway_hw_mapping,
  GamePadPreset.MicrosoftXbox360: _xbox360_hw_mapping,
};

var hw_mapping = _8bitdo_hw_mapping;

final default_gk_mapping = <GamePadControl, GameKey>{
  GamePadControl.a: GameKey.a_button,
  GamePadControl.b: GameKey.b_button,
  GamePadControl.x: GameKey.x_button,
  GamePadControl.y: GameKey.y_button,
  GamePadControl.left_bumper: GameKey.soft1,
  GamePadControl.right_bumper: GameKey.soft2,
  GamePadControl.select: GameKey.select,
  GamePadControl.start: GameKey.start,
  GamePadControl.dpad_up: GameKey.up,
  GamePadControl.dpad_down: GameKey.down,
  GamePadControl.dpad_left: GameKey.left,
  GamePadControl.dpad_right: GameKey.right,
  GamePadControl.dpad_x: GameKey.x_axis,
  GamePadControl.dpad_y: GameKey.y_axis,
  GamePadControl.analog_left_x: GameKey.x_axis,
  GamePadControl.analog_left_y: GameKey.y_axis,
  GamePadControl.analog_right_x: GameKey.x_axis,
  GamePadControl.analog_right_y: GameKey.y_axis,
  GamePadControl.throttle_left: GameKey.l_throttle,
  GamePadControl.throttle_right: GameKey.r_throttle,
};

final alternative_gk_mapping = <GamePadControl, GameKey>{
  GamePadControl.a: GameKey.a_button,
  GamePadControl.b: GameKey.x_button,
  GamePadControl.x: GameKey.b_button,
  GamePadControl.y: GameKey.y_button,
  GamePadControl.left_bumper: GameKey.x_button,
  GamePadControl.right_bumper: GameKey.y_button,
  GamePadControl.select: GameKey.soft2,
  GamePadControl.start: GameKey.soft1,
  GamePadControl.dpad_up: GameKey.up,
  GamePadControl.dpad_down: GameKey.down,
  GamePadControl.dpad_left: GameKey.left,
  GamePadControl.dpad_right: GameKey.right,
  GamePadControl.dpad_x: GameKey.x_axis,
  GamePadControl.dpad_y: GameKey.y_axis,
  GamePadControl.analog_left_x: GameKey.x_axis,
  GamePadControl.analog_left_y: GameKey.y_axis,
  GamePadControl.analog_right_x: GameKey.x_axis,
  GamePadControl.analog_right_y: GameKey.y_axis,
  GamePadControl.throttle_left: GameKey.l_throttle,
  GamePadControl.throttle_right: GameKey.r_throttle,
};

final gk_mapping = default_gk_mapping;

enum GamePadControl {
  a,
  b,
  x,
  y,
  left_bumper,
  right_bumper,
  left_trigger,
  right_trigger,
  select,
  start,
  left_stick,
  right_stick,
  dpad_up,
  dpad_down,
  dpad_left,
  dpad_right,
  under_left,
  under_right,
  dpad_x,
  dpad_y,
  analog_left_x,
  analog_left_y,
  analog_right_x,
  analog_right_y,
  throttle_left,
  throttle_right,
}

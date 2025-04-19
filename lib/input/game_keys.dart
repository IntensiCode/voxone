import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:supercharged/supercharged.dart';
import 'package:stardash/util/extensions.dart';

bool invert_y_axis = true;
bool prefer_x_over_y = true;

final typical_select_keys = [GameKey.a_button, GameKey.b_button, GameKey.soft2];

enum GameKey {
  left('Left'),
  right('Right'),
  up('Up'),
  down('Down'),
  a_button('A'),
  b_button('B'),
  x_button('X'),
  y_button('Y'),
  start('Start'),
  select('Select'),
  soft1('Soft1'),
  soft2('Soft2'),
  x_axis('X Axis'),
  y_axis('Y Axis'),
  l_throttle('L Throttle'),
  r_throttle('R Throttle'),
  ;

  final String label;

  const GameKey(this.label);
}

mixin HasGameKeys on KeyboardHandler {
  late final keyboard = HardwareKeyboard.instance;

  /// Limit keyboard mappings to not interfere with text input and game pad configuration.
  /// This will reduce navigation to arrow keys only.
  /// And the buttons will not be mapped to keyboard input anymore.
  static bool configuration_mode = false;

  static final arrowLeft = ['Arrow Left'];
  static final arrowRight = ['Arrow Right'];
  static final arrowDown = ['Arrow Down'];
  static final arrowUp = ['Arrow Up'];

  static final leftKeys = ['Arrow Left', 'A', 'H'];
  static final rightKeys = ['Arrow Right', 'D', 'L'];
  static final downKeys = ['Arrow Down', 'S', 'J'];
  static final upKeys = ['Arrow Up', 'W', 'K'];
  static final aKeys = ['V', 'Control', 'M'];
  static final bKeys = ['C', 'Space', 'E'];
  static final xKeys = ['X', 'Shift', 'N'];
  static final yKeys = ['Y', 'Alt', 'Q'];
  static final selectKeys = ['Tab', 'I'];
  static final startKeys = ['F1', 'U'];
  static final softKeys1 = ['Escape'];
  static final softKeys2 = ['Enter'];

  static final _mapping = {
    GameKey.left: leftKeys,
    GameKey.right: rightKeys,
    GameKey.up: upKeys,
    GameKey.down: downKeys,
    GameKey.a_button: aKeys,
    GameKey.b_button: bKeys,
    GameKey.x_button: xKeys,
    GameKey.y_button: yKeys,
    GameKey.select: selectKeys,
    GameKey.start: startKeys,
    GameKey.soft1: softKeys1,
    GameKey.soft2: softKeys2,
  };

  static final _config_mapping = {
    'Arrow Left': GameKey.left,
    'Arrow Right': GameKey.right,
    'Arrow Down': GameKey.down,
    'Arrow Up': GameKey.up,
    // 'Escape': GameKey.soft1,
    // 'Enter': GameKey.a_button,
  };

  static final _direct_mapping =
      _mapping.entries.expand((it) => it.value.map((label) => MapEntry(label, it.key))).toMap();

  late void Function(GameKey) onPressed = (it) => held[it] = true;
  late void Function(GameKey) onReleased = (it) => held[it] = false;

  // held states

  final Map<GameKey, bool> held = Map.fromIterable(GameKey.values, value: (_) => false);

  bool get alt => keyboard.isAltPressed;

  bool get ctrl => keyboard.isControlPressed;

  bool get meta => keyboard.isMetaPressed;

  bool get shift => keyboard.isShiftPressed;

  bool get left => held[GameKey.left] == true;

  bool get right => held[GameKey.right] == true;

  bool get up => held[GameKey.up] == true;

  bool get down => held[GameKey.down] == true;

  bool get a_button => held[GameKey.a_button] == true;

  bool get b_button => held[GameKey.b_button] == true;

  bool get x_button => held[GameKey.x_button] == true;

  bool get y_button => held[GameKey.y_button] == true;

  bool get select => held[GameKey.select] == true;

  bool get start => held[GameKey.start] == true;

  bool get soft1 => held[GameKey.soft1] == true;

  bool get soft2 => held[GameKey.soft2] == true;

  bool isHeld(GameKey key) => held[key] == true;

  List<String> _labels(LogicalKeyboardKey key) =>
      [key.keyLabel, ...key.synonyms.map((it) => it.keyLabel)].mapList((it) => it == ' ' ? 'Space' : it).toList();

  final _labels_cache = <LogicalKeyboardKey, List<String>>{};

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyRepeatEvent) {
      return true; // super.onKeyEvent(event, keysPressed);
    }
    if (event is KeyDownEvent) {
      final mapping = configuration_mode ? _config_mapping : _direct_mapping;
      final labels = _labels_cache[event.logicalKey] ??= _labels(event.logicalKey);
      for (final it in labels) {
        final gk = mapping[it];
        if (gk != null) onPressed(gk);
      }
    }
    if (event is KeyUpEvent) {
      final mapping = configuration_mode ? _config_mapping : _direct_mapping;
      final labels = _labels_cache[event.logicalKey] ??= _labels(event.logicalKey);
      for (final it in labels) {
        final gk = mapping[it];
        if (gk != null) onReleased(gk);
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }
}

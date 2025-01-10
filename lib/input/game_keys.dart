import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:voxone/util/extensions.dart';

enum GameKey {
  left,
  right,
  up,
  down,
  a_button,
  b_button,
  x_button,
  y_button,
  start,
  select,
  soft1,
  soft2,
}

mixin HasGameKeys on KeyboardHandler {
  late final keyboard = HardwareKeyboard.instance;

  static final leftKeys = ['Arrow Left', 'A', 'H'];
  static final rightKeys = ['Arrow Right', 'D', 'L'];
  static final downKeys = ['Arrow Down', 'S', 'J'];
  static final upKeys = ['Arrow Up', 'W', 'K'];
  static final aKeys = ['V', 'Control', 'M'];
  static final bKeys = ['C', 'Shift', 'E'];
  static final xKeys = ['X', 'Space', 'N'];
  static final yKeys = ['Y', 'Alt', 'Q'];
  static final selectKeys = ['Tab', 'I'];
  static final startKeys = ['F1', 'U'];
  static final softKeys1 = ['Escape'];
  static final softKeys2 = ['Enter'];

  static final mapping = {
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

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyRepeatEvent) {
      return true; // super.onKeyEvent(event, keysPressed);
    }
    if (event case KeyDownEvent it) {
      final labels = _labels(it.logicalKey);
      for (final entry in mapping.entries) {
        final key = entry.key;
        final keys = entry.value;
        if (keys.any((it) => labels.contains(it))) {
          onPressed(key);
        }
      }
    }
    if (event case KeyUpEvent it) {
      final labels = _labels(it.logicalKey);
      for (final entry in mapping.entries) {
        final key = entry.key;
        final keys = entry.value;
        if (keys.any((it) => labels.contains(it))) {
          onReleased(key);
        }
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }
}

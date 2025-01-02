import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'extensions.dart';

enum GameKey {
  left,
  right,
  up,
  down,
  fire1,
  fire2,
  use,
  inventory,
  soft1,
  soft2,
  start,
  select,
}

mixin HasGameKeys on KeyboardHandler {
  late final keyboard = HardwareKeyboard.instance;

  static final leftKeys = ['Arrow Left', 'A'];
  static final rightKeys = ['Arrow Right', 'D'];
  static final downKeys = ['Arrow Down', 'S'];
  static final upKeys = ['Arrow Up', 'W'];
  static final fireKeys1 = ['Space', 'J', 'Z'];
  static final fireKeys2 = ['Shift', 'K', 'X'];
  static final fireKeys3 = ['Control', 'H', 'C'];
  static final fireKeys4 = ['L', 'V'];
  static final selectKeys = ['Tab', 'I'];
  static final startKeys = ['U'];
  static final softKeys1 = ['Backspace', 'Escape'];
  static final softKeys2 = ['Delete', 'Enter'];

  static final mapping = {
    GameKey.left: leftKeys,
    GameKey.right: rightKeys,
    GameKey.up: upKeys,
    GameKey.down: downKeys,
    GameKey.fire1: fireKeys1,
    GameKey.fire2: fireKeys2,
    GameKey.use: fireKeys3,
    GameKey.inventory: fireKeys4,
    GameKey.soft1: softKeys1,
    GameKey.soft2: softKeys2,
    GameKey.select: selectKeys,
    GameKey.start: startKeys,
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

  bool get fire1 => held[GameKey.fire1] == true;

  bool get fire2 => held[GameKey.fire2] == true;

  bool get fire3 => held[GameKey.use] == true;

  bool get fire4 => held[GameKey.inventory] == true;

  bool get soft1 => held[GameKey.soft1] == true;

  bool get soft2 => held[GameKey.soft2] == true;

  bool get select => held[GameKey.select] == true;

  bool get start => held[GameKey.start] == true;

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

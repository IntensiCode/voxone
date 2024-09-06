import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'auto_dispose.dart';

mixin HasAutoDisposeShortcuts on Component, AutoDispose {
  bool get is_active => true;

  void onKey(String pattern, void Function() callback) {
    autoDispose(
      'key-$pattern',
      shortcuts.onKey(pattern, callback, is_active: () => is_active),
    );
  }

  void onKeys(List<String> patterns, void Function() callback) {
    patterns.forEach((it) => onKey(it, callback));
  }
}

extension ComponentExtension on Component {
  Shortcuts get shortcuts {
    Component? probed = this;
    while (probed is! Shortcuts) {
      probed = probed?.parent;
      if (probed == null) throw StateError('no shortcuts mixin found');
    }
    return probed;
  }
}

mixin Shortcuts<T extends World> on HasKeyboardHandlerComponents<T> {
  late final keyboard = HardwareKeyboard.instance;

  final handlers = <(String, void Function(), bool Function() is_active)>[];

  Disposable onKey(String pattern, void Function() callback, {bool Function()? is_active}) {
    is_active ??= () => true;
    logVerbose('onKey $pattern');
    final handler = (pattern, callback, is_active);
    handlers.add(handler);
    return Disposable.wrap(() => handlers.remove(handler));
  }

  Function(String) snoop = (it) {};

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyRepeatEvent) {
      return KeyEventResult.skipRemainingHandlers;
    }
    if (event is KeyDownEvent && event.character?.isEmpty == false) {
      final pattern = _make_full_shortcut(event);
      snoop(pattern);

      bool handled = false;
      final cloned = [...handlers]; // clone to avoid concurrent modification from add/remove handlers
      for (final it in cloned) {
        if (it.$1 == pattern && it.$3()) {
          it.$2();
          handled = true;
        }
      }
      if (handled) {
        return KeyEventResult.skipRemainingHandlers;
      } else {
        logVerbose('not handled: $pattern');
      }
    } else if (event is KeyDownEvent) {
      final pattern = _make_shortcut(event);
      snoop(pattern);

      bool handled = false;
      final cloned = [...handlers]; // clone to avoid concurrent modification from add/remove handlers
      for (final it in cloned) {
        if (it.$1 == pattern && it.$3()) {
          it.$2();
          handled = true;
        }
      }
      if (handled) {
        return KeyEventResult.skipRemainingHandlers;
      } else {
        logVerbose('not handled: $pattern');
      }
    }
    return super.onKeyEvent(event, keysPressed);
  }

  String _make_shortcut(KeyDownEvent event) {
    var pattern = '<${event.logicalKey.keyLabel}>';
    pattern = pattern.replaceFirst('Arrow ', '');
    return pattern;
  }

  String _make_full_shortcut(KeyDownEvent event) {
    final modifiers = StringBuffer();
    if (keyboard.isAltPressed) modifiers.write('A-');
    if (keyboard.isControlPressed) modifiers.write('C-');
    if (keyboard.isMetaPressed) modifiers.write('M-');
    if (keyboard.isShiftPressed) modifiers.write('S-');

    final label = event.logicalKey.keyLabel;

    var pattern = event.character ?? label;
    if (pattern == ' ') pattern = 'Space';
    pattern = pattern.replaceFirst('Arrow ', '');

    if (label.length > 1) pattern = label;

    final forceMod = keyboard.isAltPressed || keyboard.isControlPressed || keyboard.isMetaPressed;
    if (modifiers.isNotEmpty && label.length > 1 || forceMod) {
      pattern = "<$modifiers$pattern>";
    } else if (pattern.length > 1) {
      pattern = "<$pattern>";
    }
    return pattern;
  }
}

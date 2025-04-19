import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:supercharged/supercharged.dart';
import 'package:stardash/background/space.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/screens.dart';
import 'package:stardash/input/keys.dart';
import 'package:stardash/input/shortcuts.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/ui/highlighted.dart';
import 'package:stardash/ui/soft_keys.dart';
import 'package:stardash/util/bitmap_text.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/game_script.dart';

class SelectGamePad extends GameScriptComponent {
  final _keys = Keys();

  late Map<String, Map<int, GamePadControl>> _data;

  late BitmapText _showing_input;

  @override
  onLoad() async {
    super.onLoad();
    add(_keys);
    add(space);

    _data = await _load_data();

    fontSelect(tiny_font, scale: 2);
    textXY('Select Game Pad', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);
    textXY('Type name of your Game Pad to filter:', game_center.x, 48, scale: 1.5, anchor: Anchor.topCenter);
    _showing_input = textXY('> ', game_center.x, 64, scale: 1.5, anchor: Anchor.topCenter);

    softkeys('Back', null, (_) => popScreen()).withGameKeys(_keys, GameKey.soft1);

    _show_matches(_data.entries.toList());
  }

  static const _max_showing = 16;
  final _current_matches = <MapEntry<String, Map<int, GamePadControl>>>[];
  final _showing_matches = <BitmapText>[];
  int _selected = -1;
  int _offset = 0;

  void _show_matches(List<MapEntry<String, Map<int, GamePadControl>>> matches) async {
    logInfo('update matches: ${matches.length}');

    _offset = 0;
    _selected = 0;
    _pending_select = 0;

    _current_matches.clear();
    _current_matches.addAll(matches);

    _update_matches();
  }

  void _update_matches() {
    for (final it in _showing_matches) {
      it.removeFromParent();
    }
    _showing_matches.clear();

    final show = _current_matches.skip(_offset).take(_max_showing);

    var y = 100.0;
    for (final match in show) {
      _showing_matches.add(added(BitmapText(
        text: match.key,
        position: Vector2(game_center.x, y),
        anchor: Anchor.topCenter,
      )));
      y += 20;
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    HasGameKeys.configuration_mode = false;
  }

  @override
  void onMount() {
    super.onMount();
    autoDispose('snoop_key_input', snoop_key_input(_handle_key));
    HasGameKeys.configuration_mode = true;
  }

  final _undo = <String>[];
  var _input = '';

  void _handle_key(String it) {
    if (it == '<Escape>') {
      if (_input.isEmpty) {
        popScreen();
      } else {
        _undo.add(_input);
        _input = '';
      }
    } else if (it == '<C-w>' || it == '<C-u>') {
      _undo.add(_input);
      _input = '';
    } else if (it == '<C-z>') {
      final last = _undo.removeLastOrNull();
      if (last != null) _input = last;
    } else if (it == '<Backspace>') {
      _undo.add(_input);
      if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
    } else if (it == '<Space>') {
      _input += ' ';
    } else if (it == '<Enter>') {
      _activate_selected_and_pop();
    } else if (it.length == 1) {
      _input += it;
    } else {
      logInfo('todo: $it');
    }

    if (_showing_input.text == '> $_input') return;
    _showing_input.text = '> $_input';

    final sanitized = _input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final start = _data.filter((it) => it.key.toLowerCase().startsWith(sanitized.toLowerCase()));
    final matches = _data.filter((it) => it.key.toLowerCase().contains(sanitized.toLowerCase()));
    final full_pattern = RegExp('.*${sanitized.characters.map((it) => '${it.toLowerCase()}.*').join('')}');
    final full_matches = _data.filter((it) => it.key.toLowerCase().contains(full_pattern));
    final all = (start + matches + full_matches).toList().distinctBy((it) => it.key).toList();
    logInfo('matches: ${all.length}');

    _offset = 0;
    _show_matches(all);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.up)) _pending_select = -1;
    if (_keys.check_and_consume(GameKey.down)) _pending_select = 1;
    if (_keys.any(typical_select_keys)) _activate_selected_and_pop();
    // if (_keys.check_and_consume(GameKey.soft1)) popScreen();
    _do_select();
  }

  int? _pending_select;

  void _do_select() {
    final step = _pending_select;
    if (step == null) return;
    _pending_select = null;

    if (_showing_matches.isEmpty) return;

    _selected = (step + _selected) % _current_matches.length;

    if (_selected < _offset) {
      _offset = _selected;
      _update_matches();
    } else if (_selected >= _offset + _max_showing) {
      _offset = _selected - _max_showing + 1;
      _update_matches();
    } else {
      for (final it in _showing_matches) {
        final c = it.text.replaceAll(RegExp(r'^> | <$'), '');
        if (it.text != c) {
          it.text = c;
          it.fadeInDeep();
        }
        it.children.whereType<Highlighted>().forEach((it) => it.removeFromParent());
      }
    }

    final target = _showing_matches[_selected - _offset];
    target.text = '> ${target.text} <';
    target.add(Highlighted());
    target.fadeInDeep();
  }

  void _activate_selected_and_pop() {
    if (_selected < 0 || _selected >= _current_matches.length) return;
    final it = _current_matches[_selected];
    logInfo('selected: ${it.key}');
    hw_mapping = it.value;
    popScreen();
  }
}

Future<Map<String, Map<int, GamePadControl>>> _load_data() async {
  final result = <String, Map<int, GamePadControl>>{};

  final data = await game.assets.readFile('data/game_pad.csv');
  final entries = data.split('\n').skip(2);
  for (final entry in entries) {
    final parts = entry.split(',');
    if (parts.length < 2) continue;

    final name = parts[0];

    final input = parts.skip(1).toList();
    input.removeLast();
    input.removeLast();

    final raw = input.map(_convert_mapping);
    // if (dev && raw.contains(null)) logInfo('missing translation(s): $input');

    final mapping = raw.nonNulls.map((it) => MapEntry(it.$1, it.$2)).toMap();
    // if (dev && mapping.length < 10) logInfo('ok? $mapping $input');

    if (!result.containsKey(name)) result[name] = mapping;
  }

  return result;
}

(int, GamePadControl)? _convert_mapping(String it) {
  if (it.startsWith('misc:') || it.startsWith('guide:')) return null;

  if (it == 'dpup:h0.1') return (107, GamePadControl.dpad_y);
  if (it == 'dpdown:h0.4') return (107, GamePadControl.dpad_y);
  if (it == 'dpleft:h0.8') return (106, GamePadControl.dpad_x);
  if (it == 'dpright:h0.2') return (106, GamePadControl.dpad_x);

  if (it == 'dpup:h0.4') return (107 /*TODO*/, GamePadControl.dpad_y);
  if (it == 'dpdown:h0.8') return (107 /*TODO*/, GamePadControl.dpad_y);
  if (it == 'dpleft:h0.2') return (106 /*TODO*/, GamePadControl.dpad_x);
  if (it == 'dpright:h0.1') return (106 /*TODO*/, GamePadControl.dpad_x);

  // if (it == 'dpup:h0.4') return (107/*TODO*/, GamePadControl.dpad_y);
  if (it == 'dpdown:h0.1') return (107 /*TODO*/, GamePadControl.dpad_y);
  // if (it == 'dpleft:h0.2') return (106/*TODO*/, GamePadControl.dpad_x);
  if (it == 'dpright:h0.8') return (106 /*TODO*/, GamePadControl.dpad_x);

  final parts = it.split(':');

  final gpc = _gpc_for(parts[0]);
  // if (gpc == null && dev) logInfo('no mapping for: $parts');
  if (gpc == null) return null;

  final id = _id_for(parts[1], it);
  // if (id == null && dev) logInfo('no mapping for: $parts');
  if (id == null) return null;

  // axis for dpad? dpad_x and dpad_y instead!
  if (id.abs() >= 300) {
    if (gpc == GamePadControl.dpad_up || gpc == GamePadControl.dpad_down) {
      return (id.abs() - 200, GamePadControl.dpad_y);
    }
    if (gpc == GamePadControl.dpad_left || gpc == GamePadControl.dpad_right) {
      return (id.abs() - 200, GamePadControl.dpad_x);
    }
  }

  return (id, gpc);
}

GamePadControl? _gpc_for(String id) => switch (id) {
      'a' => GamePadControl.a,
      'b' => GamePadControl.b,
      'back' => GamePadControl.select,
      'dpdown' => GamePadControl.dpad_down,
      'dpleft' => GamePadControl.dpad_left,
      'dpright' => GamePadControl.dpad_right,
      'dpup' => GamePadControl.dpad_up,
      'leftshoulder' => GamePadControl.left_bumper,
      'leftstick' => GamePadControl.left_stick,
      'lefttrigger' => GamePadControl.throttle_left,
      'leftx' => GamePadControl.analog_left_x,
      'lefty' => GamePadControl.analog_left_y,
      'rightshoulder' => GamePadControl.right_bumper,
      'rightstick' => GamePadControl.right_stick,
      'righttrigger' => GamePadControl.throttle_right,
      'rightx' => GamePadControl.analog_right_x,
      'righty' => GamePadControl.analog_right_y,
      'start' => GamePadControl.start,
      'x' => GamePadControl.x,
      'y' => GamePadControl.y,
      _ => null
    };

final _match_button = RegExp(r'b(\d+)');
final _match_axis = RegExp(r'a(\d+)');

int? _id_for(String id, String hint) {
  // if id matches b<number> then return the number plus 200:
  final b = _match_button.firstMatch(id);
  if (b != null) return int.parse(b.group(1)!) + 200;

  // if id matches a<number> then return the number plus 100:
  final a = _match_axis.firstMatch(id);
  if (a != null) {
    final value = int.parse(a.group(1)!);
    if (id[0] == '-' || id[0] == '+') {
      return (value + 300) * (id[0] == '-' ? -1 : 1);
    }
    return value + 100;
  }

  if (id == 'h0.1' || id == 'h0.4') TODO(hint);
  if (id == 'h0.2' || id == 'h0.8') TODO(hint);

  return null;
}

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../core/common.dart';
import '../util/auto_dispose.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/effects.dart';
import '../util/extensions.dart';
import '../util/game_script_functions.dart';
import '../util/keys.dart';
import '../util/mouse_wheel_scrolling.dart';
import '../util/on_message.dart';

class ScrolledText extends PositionComponent with AutoDispose, GameScriptFunctions, DragCallbacks, MouseWheelScrolling {
  //
  late final Keys _keys;
  late final List<String> _lines;
  late final int _visible_lines;
  late final int _max_scroll;
  final BitmapFont _font;

  late final BitmapText _up_indicator;
  late final BitmapText _down_indicator;
  final List<BitmapText> _showing = [];

  ScrolledText({
    required String text,
    required BitmapFont font,
    required Vector2 size,
    super.position,
    super.anchor,
    super.scale,
  })  : _font = font,
        super(size: size) {
    add(_keys = Keys());
    //
    _lines = text.lines().map((it) => _font.reflow(it, (size.x - _font.lineWidth(' ')).toInt())).flattened.toList();

    _visible_lines = size.y ~/ _font.lineHeight() - 3 /*indicators*/;
    _max_scroll = _lines.length - _visible_lines;

    _up_indicator = added(BitmapText(
      text: '[More]',
      font: _font,
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 0),
    ));
    _up_indicator.add(HighlightEffect(color: black, opacity: 0.5, duration: 0.5, repeat: true));

    _down_indicator = added(BitmapText(
      text: '[More]',
      font: _font,
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, size.y),
    ));
    _down_indicator.add(HighlightEffect(color: black, opacity: 0.5, duration: 0.5, repeat: true));

    _update_shown_lines();
    _update_indicators();
  }

  void _update_shown_lines() {
    _showing.forEach((it) => it.removeFromParent());
    _showing.clear();

    final line_height = _font.lineHeight();
    final add_pos = Vector2(size.x / 2, line_height * 2);
    final lines = _lines.skip(_scroll_pos).take(_visible_lines).map((line) {
      final it = BitmapText(text: line, font: _font, anchor: Anchor.topCenter, position: add_pos);
      add_pos.y += line_height;
      return it;
    });

    _showing.addAll(lines);
    _showing.forEach(add);
  }

  _update_indicators() {
    _up_indicator.isVisible = _scroll_pos > 0;
    _down_indicator.isVisible = _scroll_pos < _max_scroll;
  }

  @override
  void onMount() {
    super.onMount();
    // onKeys(['k', '<Up>'], () => _scroll_up());
    // onKeys(['j', '<Down>'], () => _scroll_down());
    onMessage<MouseWheel>((it) => it.direction < 0 ? _scroll_up() : _scroll_down());
  }

  @override
  update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.up)) _scroll_up();
    if (_keys.check_and_consume(GameKey.down)) _scroll_down();
  }

  int _scroll_pos = 0;

  void _scroll_up() {
    if (_scroll_pos <= 0) return;
    _scroll_pos--;
    _update_shown_lines();
    _update_indicators();
  }

  void _scroll_down() {
    if (_scroll_pos >= _max_scroll) return;
    _scroll_pos++;
    _update_shown_lines();
    _update_indicators();
  }

  @override
  double get drag_step => _font.lineHeight();

  @override
  void onDragSteps(int steps) {
    _scroll_pos = (_scroll_pos - steps).clamp(0, _max_scroll);
    _update_shown_lines();
    _update_indicators();
  }
}

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../util/bitmap_font.dart';
import '../util/delayed.dart';
import '../util/extensions.dart';
import '../util/random.dart';

class FallingText extends PositionComponent {
  static double time_per_page = 4.0;

  final BitmapFont _font;

  late final List<_TextPage> _pages;

  _State _state = _State.next_screen;
  double _wait_time = time_per_page;
  _TextPage? _current_page;

  FallingText(
    this._font,
    String text, {
    required Vector2 position,
    required Vector2 size,
    super.anchor,
  }) : super(position: position, size: size) {
    _pages = text.split('~\n').map((it) => _TextPage(_font, it, size)).toList();
  }

  @override
  void update(double dt) {
    switch (_state) {
      case _State.fall_down:
        _fallDown();
        break;
      case _State.next_screen:
        _nextScreen(dt);
        break;
      case _State.wait:
        _wait(dt);
        break;
    }
  }

  _fallDown() {
    if (_current_page?.active == false) {
      _current_page?.removeFromParent();
      _state = _State.next_screen;
    }
  }

  _nextScreen(double dt) {
    _current_page = _pages.nextAfter(_current_page);
    _current_page?.reset();
    add(_current_page!);
    _state = _State.wait;
  }

  _wait(double dt) {
    if ((_wait_time -= dt) <= 0) {
      _wait_time = time_per_page;
      _current_page?.start_falling();
      _state = _State.fall_down;
    }
  }
}

class _TextPage extends PositionComponent {
  final BitmapFont _font;
  final List<String> _lines;

  Iterable<_FallingChar> get _characters => children.whereType<_FallingChar>();

  bool get active => _characters.any((it) => it.active);

  _TextPage(this._font, String text, Vector2 container_size)
      : _lines = text.split('\n'),
        super(size: container_size) {
    //
    final int count = _lines.fold(0, (acc, line) => acc + line.length);

    var y = _font.lineHeight() / 2;
    for (final line in _lines) {
      //
      var x = (container_size.x - _font.lineWidth(line)) / 2;

      for (int idx = 0; idx < line.length; idx++) {
        final it = line.codeUnitAt(idx);
        final start_at = children.length / count;
        add(_FallingChar(
          sprite: _font.sprite(it),
          position: Vector2(x, y),
          start_at: start_at,
          fall_height: size.y,
        ));
        x += _font.charWidth(it) + _font.spacing;
      }
      y += _font.lineHeight() + _font.spacing;
    }
  }

  void reset() => _characters.forEach((it) => it.reset());

  void start_falling() => _characters.forEach((it) => it.active = true);
}

enum _State {
  fall_down,
  next_screen,
  wait,
}

class _FallingChar extends SpriteComponent with HasVisibility {
  final double _fall_height;
  final double _start_time;
  final Vector2 _start_pos;

  bool active = false;

  _FallingChar({
    required Sprite sprite,
    required Vector2 position,
    required double fall_height,
    required double start_at,
  })  : _fall_height = fall_height,
        _start_time = start_at,
        _start_pos = position,
        super(sprite: sprite, position: position);

  reset() {
    position.setFrom(_start_pos);
    _wait_time = _start_time + rng.nextDoubleLimit(0.3);
    _fall_speed = 0;
    opacity = 0;
    add(Delayed(_wait_time, () => add(_ZoomInEffect())));
  }

  double _wait_time = 0;
  double _fall_speed = 0;

  @override
  void update(double dt) {
    if (!active) return;

    _wait_time -= dt;
    if (_wait_time > 0) return;

    _fall_speed += 8 * dt;

    position.y += _fall_speed;
    active = position.y < _fall_height;

    opacity = Curves.easeIn.transform((1 - position.y / _fall_height).clamp(0, 1));
  }
}

class _ZoomInEffect extends ComponentEffect<SpriteComponent> {
  _ZoomInEffect() : super(CurvedEffectController(0.7, Curves.easeInOutCubic));

  @override
  void apply(double progress) {
    (parent as SpriteComponent).opacity = progress;
    (parent as SpriteComponent).scale.setAll(1 + 4 - progress * 4);
  }
}

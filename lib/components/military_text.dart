import 'package:collection/collection.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../core/common.dart';
import '../game/soundboard.dart';
import '../util/bitmap_font.dart';
import '../util/delayed.dart';
import '../util/extensions.dart';

enum _State {
  fall_down,
  next_screen,
  wait,
}

class MilitaryText extends Component {
  MilitaryText({
    required this.font,
    required this.font_scale,
    required this.text,
    this.stay_seconds = 1,
    this.time_per_char = 0.1,
    required this.when_done,
  });

  final BitmapFont font;
  final double font_scale;
  final String text;
  final double stay_seconds;
  final double time_per_char;
  final Hook when_done;

  late final List<_TextPage> _pages;

  _State _state = _State.next_screen;
  _TextPage? _current_page;
  double _wait_time = 0;

  @override
  Future onLoad() async {
    super.onLoad();
    _pages = text.split('~\n').map((it) => _TextPage(font, font_scale, it, time_per_char)).toList();

    await soundboard.preload_one_shot('splash_shot.ogg');
    await soundboard.preload_one_shot('splash_wipe.ogg');
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

  void _fallDown() {
    if (_current_page?.active == false) {
      _current_page?.removeFromParent();
      _state = _State.next_screen;
    }
  }

  void _nextScreen(double dt) {
    if (_pages.last == _current_page) {
      when_done();
      removeFromParent();
    } else {
      final it = _current_page = _pages.nextAfter(_current_page);
      if (it != null) {
        add(it);
      } else {
        when_done();
        removeFromParent();
      }
      _state = _State.wait;
    }
  }

  void _wait(double dt) {
    if (_current_page?.ready == false) {
      return;
    } else if ((_wait_time += dt) >= stay_seconds) {
      _wait_time = 0;
      _current_page?.start_falling();
      _state = _State.fall_down;
      _wipe();
    }
  }

  Future _wipe() async => await soundboard.play_one_shot_sample('splash_wipe.ogg');
}

class _TextPage extends Component with AutoDispose {
  _TextPage(BitmapFont font, double font_scale, String text, double time_per_char) {
    final lines = text.split('\n').map((it) => it.trim()).whereNot((it) => it.isEmpty);

    double start_at = 0;

    font.scale = font_scale;
    var y = (game_height - font.lineHeight(font_scale) * lines.length) / 2 + 8;
    for (final line in lines) {
      var x = center_x - font.lineWidth(line) / 2;
      for (int idx = 0; idx < line.length; idx++) {
        final it = line.codeUnitAt(idx);
        add(_MilitaryChar(
          sprite: font.sprite(it),
          target_scale: font_scale,
          start_position: Vector2(x, y),
          start_at: start_at,
        ));
        x += font.charWidth(it, font_scale) + font.spacing * font_scale;
        start_at += time_per_char;
      }
      y += font.lineHeight(font_scale) + font.spacing * font_scale;
    }

    add(Delayed(start_at, () => dispose('shot')));

    _reset();
    removed.then((_) => _reset());
  }

  @override
  Future onLoad() async {
    super.onLoad();
    autoDispose('shot', await soundboard.play_one_shot_sample('splash_shot.ogg', loop: true));
  }

  void _reset() => _characters.forEach((it) => it.reset());

  bool get ready => _characters.every((it) => it.ready);

  bool get active => _characters.any((it) => it.falling);

  Iterable<_MilitaryChar> get _characters => children.whereType<_MilitaryChar>();

  void start_falling() => _characters.forEach((it) => it.falling = true);
}

class _MilitaryChar extends SpriteComponent with HasVisibility {
  _MilitaryChar({
    required Sprite sprite,
    required this.target_scale,
    required this.start_position,
    required this.start_at,
  }) : super(sprite: sprite, position: start_position);

  final double target_scale;
  final double start_at;
  final Vector2 start_position;

  bool ready = false;
  bool falling = false;
  double fall_speed = 0;

  void reset() {
    position.setFrom(start_position);
    ready = false;
    falling = false;
    fall_speed = 0;
    opacity = 0;
    add(Delayed(start_at, () {
      add(_ZoomInEffect(target_scale)..removed.then((_) => ready = true));
    }));
  }

  @override
  void onLoad() {
    super.onLoad();
    reset();
  }

  @override
  void update(double dt) {
    if (!falling) return;

    fall_speed += 32 * dt;

    position.y -= fall_speed;
    falling = position.y > -50;

    opacity = (opacity - 0.05).clamp(0, 1);
  }
}

class _ZoomInEffect extends ComponentEffect<SpriteComponent> {
  _ZoomInEffect(this._target_scale) : super(CurvedEffectController(0.2, Curves.easeInOutCubic));

  final double _target_scale;

  @override
  void apply(double progress) {
    (parent as SpriteComponent).opacity = progress;
    (parent as SpriteComponent).scale.setAll(_target_scale + 4 - progress * 4);
  }
}

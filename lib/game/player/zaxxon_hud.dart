import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/player/zaxxon_player.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/player_target.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/mut_rect.dart';

class ZaxxonHud extends Component with HasContext, HasPaint {
  ZaxxonHud() {
    add(BitmapText(text: 'SHIELD', position: Vector2(16, 16))..renderSnapshot = true);
    add(BitmapText(text: 'INTEGRITY', position: Vector2(16, 32))..renderSnapshot = true);
    // add(BitmapText(text: 'OVERHEAT', position: Vector2(16, 48))..renderSnapshot = true);
  }

  ZaxxonPlayer get _player => player as ZaxxonPlayer;

  @override
  void render(Canvas canvas) {
    final e = _player.shield?.energy;
    if (e != null) {
      paint.color = switch (e) {
        > .7 => _good,
        > .5 => _damaged,
        > .2 => _danger,
        _ => _critical,
      };
      _rect.left = 16;
      _rect.top = 26;
      _rect.right = 16 + e * 100;
      _rect.bottom = 30;
      canvas.drawRect(_rect, paint);
    }

    final i = _player.integrity;
    paint.color = switch (i) {
      > .6 => _good,
      > .5 => _damaged,
      > .2 => _danger,
      _ => _critical,
    };
    _rect.left = 16;
    _rect.top = 26 + 16;
    _rect.right = 16 + i * 100;
    _rect.bottom = 30 + 16;
    canvas.drawRect(_rect, paint);
  }

  final _rect = MutRect(0, 0, 0, 0);

  final _good = white;
  final _damaged = const Color(0xFFf0f060);
  final _danger = const Color(0xFFf0a060);
  final _critical = const Color(0xF0ff4040);
}

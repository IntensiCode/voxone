import 'package:flame/components.dart';

import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/screens.dart';
import 'game/hiscore.dart';
import 'util/bitmap_font.dart';
import 'util/bitmap_text.dart';
import 'util/effects.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';
import 'util/functions.dart';
import 'util/game_keys.dart';
import 'util/game_script.dart';
import 'util/shortcuts.dart';

class HiscoreScreen extends GameScriptComponent with HasAutoDisposeShortcuts, KeyboardHandler, HasGameKeys {
  final _entry_size = Vector2(game_width, default_line_height);
  final _position = Vector2(0, default_line_height * 4);

  @override
  onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('Hiscore', center_x, 16, scale: 2);

    _add('Score', 'Round', 'Name');
    for (final entry in hiscore.entries) {
      final it = _add(entry.score.toString(), entry.level.toString(), entry.name);
      if (entry == hiscore.latestRank) {
        it.add(BlinkEffect(on: 0.75, off: 0.25));
      }
    }

    softkeys('Back', null, (_) => popScreen());
  }

  _HiscoreEntry _add(String score, String level, String name) {
    final it = added(_HiscoreEntry(
      score,
      level,
      name,
      tiny_font,
      size: _entry_size,
      position: _position,
    ));
    _position.y += default_line_height;
    return it;
  }
}

class _HiscoreEntry extends PositionComponent with HasVisibility {
  final BitmapFont _font;

  _HiscoreEntry(
    String score,
    String level,
    String name,
    this._font, {
    required Vector2 size,
    super.position,
  }) : super(size: size) {
    add(BitmapText(
      text: score,
      position: Vector2(100, 0),
      font: _font,
      anchor: Anchor.topCenter,
    ));

    add(BitmapText(
      text: level,
      position: Vector2(160, 0),
      font: _font,
      anchor: Anchor.topCenter,
    ));

    add(BitmapText(
      text: name,
      position: Vector2(220, 0),
      font: _font,
      anchor: Anchor.topCenter,
    ));
  }
}

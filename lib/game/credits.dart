import 'package:flame/components.dart';

import '../components/flow_text.dart';
import '../core/common.dart';
import '../util/bitmap_text.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import '../util/game_script.dart';
import '../util/keys.dart';
import 'game_dialog.dart';

class Credits extends GameScriptComponent {
  static final _dialog_size = Vector2(640, 400);

  @override
  void onLoad() async {
    var text = await game.assets.readFile('data/credits.txt');
    text = text;

    final content = PositionComponent(
      size: Vector2(640, 480),
      children: [
        BitmapText(
          text: 'Credits',
          font: menu_font,
          position: Vector2(_dialog_size.x / 2, 32),
          anchor: Anchor.center,
        ),
        FlowText(
          text: text,
          font: menu_font,
          font_scale: 0.5,
          position: Vector2(_dialog_size.x / 2, _dialog_size.y - 0),
          size: Vector2(640 - 23, 400 - 72),
          anchor: Anchor.bottomCenter,
        ),
      ],
    );

    await add(GameDialog(
      size: _dialog_size,
      content: content,
      keys: DialogKeys(
        handlers: {
          GameKey.soft1: () => fadeOutDeep(),
          GameKey.soft2: () => fadeOutDeep(),
        },
        left: 'Ok',
        tap_key: GameKey.soft2,
      ),
    )..fadeInDeep());
  }
}

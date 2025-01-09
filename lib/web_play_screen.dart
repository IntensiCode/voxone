import 'package:flame/components.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/bitmap_button.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/shortcuts.dart';

class WebPlayScreen extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  @override
  void onMount() => onKey('<Space>', () => _leave());

  @override
  onLoad() async {
    add(BitmapButton(
      bg_nine_patch: atlas.sprite('button_plain.png'),
      text: 'Start',
      font: menu_font,
      font_scale: 0.5,
      position: Vector2(game_width / 2, game_height / 2),
      anchor: Anchor.center,
      onTap: (_) => _leave(),
    ));
  }

  void _leave() {
    fadeOutDeep();
    showScreen(Screen.title, skip_fade_out: true, skip_fade_in: true);
    removeFromParent();
  }
}

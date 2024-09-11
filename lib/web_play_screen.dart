import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/core/screens.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/bitmap_button.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/fonts.dart';
import 'package:voxone/util/shortcuts.dart';

class WebPlayScreen extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  @override
  void onMount() => onKey('<Space>', () => _leave());

  @override
  onLoad() async {
    final button = await images.load('button_plain.png');
    const scale = 0.5;
    add(BitmapButton(
      bg_nine_patch: button,
      text: 'Start',
      font: menu_font,
      font_scale: scale,
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

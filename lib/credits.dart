import 'package:flame/components.dart';
import 'package:stardash/background/space.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/screens.dart';
import 'package:stardash/game/stage1/appearing_moon.dart';
import 'package:stardash/input/keys.dart';
import 'package:stardash/ui/basic_menu.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/game_script.dart';

final credits = [
  'A Psychocell Game',
  'An IntensiCode Presentation',
  'A BerlinFactor Production',
  '',
  'Powered by Flutter',
  'Made with Flame Engine',
  '',
  'Music by suno.com',
  'Voxel Models by maxparata.itch.io',
  'Star Nest Shader by Pablo Roman Andrioli',
  '',
  'Voice Samples by elevenlabs.io',
  '',
  'Pixel Explosion Shader by Leukbaars',
  'Noise Shader by Dave_Hoskins',
  'Hex Shield Shader by FabriceNeyret2',
  'Moon Shader by Kali',
  'Plasma Orb Shader by Tsuki',
  'Plasma Globe by nimitz',
  '',
  '2D Art by Various Artists on itch.io',
];

class Credits extends GameScriptComponent {
  final _keys = Keys();

  @override
  onLoad() {
    super.onLoad();
    add(_keys);
    add(space);
    add(AppearingMoon()..fix_at(4, 2.5));

    textXY('Credits', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);

    final start = game_height - 128 - credits.length * 10;
    for (final (idx, it) in credits.indexed) {
      textXY(it, game_center.x, start + idx * 10, anchor: Anchor.center, scale: 1);
    }

    final menu = added(BasicMenu(
      keys: _keys,
      font: mini_font,
      onSelected: (_) => popScreen(),
      spacing: 10,
    ));

    menu.position.setValues(game_center.x, 64);
    menu.anchor = Anchor.topCenter;

    add(menu.addEntry('back', 'Back', size: Vector2(80, 24))
      ..auto_position = false
      ..position.setValues(8, game_size.y - 8)
      ..anchor = Anchor.bottomLeft);

    menu.preselectEntry('back');
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.soft1)) popScreen();
  }
}

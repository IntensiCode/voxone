import 'package:flame/components.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/stage1/appearing_moon.dart';
import 'package:voxone/input/keys.dart';
import 'package:voxone/ui/soft_keys.dart';
import 'package:voxone/util/game_script.dart';

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

    softkeys('Back', null, (_) => popScreen()).withGameKeys(_keys, GameKey.soft1);
  }
}

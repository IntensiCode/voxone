import 'package:stardash/background/checkerboard.dart';
import 'package:stardash/background/space.dart';
import 'package:stardash/game/manta.dart';
import 'package:stardash/game/player/tunnel_player.dart';
import 'package:stardash/game/scene3d.dart';
import 'package:stardash/game/shared/game_screen.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/shadows.dart';

class Stage3 extends GameScreen with HasContext {
  @override
  onLoad() async {
    // add(Checkerboard());
    add(space);
    add(shadows);
    // add(TunnelPlayer());
    // shadows.isVisible = false;

    add(MantaComponent());
    add(Scene3d());
  }
}

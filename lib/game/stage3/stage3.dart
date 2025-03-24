import 'package:voxone/background/checkerboard.dart';
import 'package:voxone/game/player/tunnel_player.dart';
import 'package:voxone/game/shared/game_screen.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/shadows.dart';

class Stage3 extends GameScreen with HasContext {
  @override
  onLoad() async {
    add(Checkerboard());
    add(shadows);
    add(TunnelPlayer());
    // shadows.isVisible = false;
  }
}

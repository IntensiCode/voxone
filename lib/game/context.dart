import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/game/configuration.dart';
import 'package:voxone/game/decals.dart';
import 'package:voxone/game/extras.dart';
import 'package:voxone/game/game_phase.dart';
import 'package:voxone/game/game_screen.dart';
import 'package:voxone/game/game_state.dart';
import 'package:voxone/game/player.dart';
import 'package:voxone/game/shadows.dart';
import 'package:voxone/game/visual.dart';
import 'package:voxone/main_controller.dart';
import 'package:voxone/util/keys.dart';

// to make these available to the tiny components, singletons are just fine:

late GameScreen stage;

late HorizontalPlayer h_player;

mixin Context on Component {
  GameScreen? _model;
  Keys? _keys;
  Shadows? _shadows;
  CollisionDetection<ShapeHitbox, Sweep<ShapeHitbox>>? _collision;

  GameScreen get model {
    final it = _model ?? findParent<GameScreen>(includeSelf: true);
    if (it != null) return it;
    throw 'no game found in $this';
  }

  Configuration get configuration => Configuration.instance;

  Visual get visual => Visual.instance;

  GamePhase get phase => model.phase;

  GameState get game_state => model.state;

  Keys get keys => _keys ??= model.keys;

  Shadows get shadows => _shadows ??= model.shadows;

  Decals get decals => model.decals;

  Extras get extras => model.extras;

  CollisionDetection<ShapeHitbox, Sweep<ShapeHitbox>> get collision =>
      _collision ??= (model.parent as MainController).collisionDetection;
}

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/configuration.dart';
import 'package:voxone/core/game_phase.dart';
import 'package:voxone/core/shadows.dart';
import 'package:voxone/core/visual.dart';
import 'package:voxone/game/extras.dart';
import 'package:voxone/game/game_screen.dart';
import 'package:voxone/main_controller.dart';
import 'package:voxone/util/keys.dart';

// to make these available to the tiny components, singletons are just fine:

late GameScreen stage;

mixin HasContext on Component {
  Context? _context;

  Context get context => _context ??= findParent<Context>(includeSelf: true)!;
}

mixin Context on Component {
  final cache = <String, Object>{};

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

  Keys get keys => _keys ??= model.keys;

  // Shadows get shadows => _shadows ??= model.shadows;

  // Decals get decals => model.decals;

  Extras get extras => model.extras;

  CollisionDetection<ShapeHitbox, Sweep<ShapeHitbox>> get collision =>
      _collision ??= (model.parent as MainController).collisionDetection;
}

import 'package:voxone/game/game_entities.dart';
import 'package:voxone/game/level/level.dart';
import 'package:voxone/game/player/player.dart';
import 'package:voxone/game/visual_configuration.dart';
import 'package:voxone/util/keys.dart';
import 'package:flame/components.dart';

import 'game_configuration.dart';
import 'game_model.dart';
import 'game_phase.dart';
import 'game_screen.dart';
import 'game_state.dart';

// to make these available to the tiny components, singletons are just fine:

late GameEntities entities;
late GameModel model;
late Level level;
late Player player;

mixin GameContext on Component {
  GameModel? _model;
  Keys? _keys;
  Level? _level;
  Player? _player;

  GameModel get model {
    final it = _model ??
        findParent<GameModel>(includeSelf: true) ?? //
        findParent<GameScreen>(includeSelf: true)?.model;
    if (it != null) return it;
    throw 'no game found in $this';
  }

  GameConfiguration get configuration => GameConfiguration.instance;

  VisualConfiguration get visual => VisualConfiguration.instance;

  GamePhase get phase => model.phase;

  GameState get game_state => model.state;

  Keys get keys => _keys ??= model.keys;

  GameEntities get entities => model.entities;

  Level get level => _level ??= model.level;

  Player get player => _player ??= model.player;
}

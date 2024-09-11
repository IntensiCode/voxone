import 'package:dart_minilog/dart_minilog.dart';
import 'package:voxone/util/game_data.dart';
import 'package:voxone/util/storage.dart';

final state = GameState.instance;

class GameState with HasGameData {
  static final instance = GameState._();

  GameState._();

  var stage = 1;

  bool game_complete = false;

  reset() async {
    logInfo('reset game state');
    stage = 1;
    game_complete = false;
  }

  preload() async {
    await load('game_state', this);
    logInfo('loaded game state: $stage');
  }

  delete() async {
    logInfo('delete game state');
    await clear('game_state');
  }

  save_checkpoint() async {
    logInfo('save game state');
    await save('game_state', this);
  }

  // HasGameData

  @override
  void load_state(GameData data) {
    stage = data['level_number_starting_at_1'];
  }

  @override
  GameData save_state(GameData data) => data..['level_number_starting_at_1'] = stage;
}

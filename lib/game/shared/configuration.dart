import 'package:voxone/core/common.dart' as common;
import 'package:voxone/game/shared/difficulty.dart' as d;
import 'package:voxone/input/game_keys.dart' as keys;
import 'package:voxone/util/game_data.dart';
import 'package:voxone/util/storage.dart' as storage;

final configuration = Configuration._();

class Configuration with HasGameData {
  Configuration._();

  bool get debug => common.debug;

  set debug(bool value) {
    common.debug = value;
    storage.save('configuration', this);
  }

  d.Difficulty get difficulty => d.difficulty;

  set difficulty(d.Difficulty value) {
    d.difficulty = value;
    storage.save('configuration', this);
  }

  Future<void> load() async => await storage.load('configuration', this);

  keys.GamePadConfig get game_pad_config => keys.game_pad_config;

  set game_pad_config(keys.GamePadConfig value) {
    keys.game_pad_config = value;
    storage.save('configuration', this);
  }

  // HasGameData

  @override
  void load_state(Map<String, dynamic> data) {
    common.debug = data['debug'] ?? common.debug;
    d.difficulty = d.Difficulty.values.firstWhere(
      (it) => it.name == data['difficulty'],
      orElse: () => d.difficulty,
    );
    keys.game_pad_config = keys.GamePadConfig.values.firstWhere(
      (it) => it.mapping == data['game_pad_config'],
      orElse: () => keys.game_pad_config,
    );
  }

  @override
  GameData save_state(Map<String, dynamic> data) => data
    ..['debug'] = common.debug
    ..['difficulty'] = d.difficulty.name
    ..['game_pad_config'] = keys.game_pad_config.mapping;
}

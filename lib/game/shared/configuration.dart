import 'package:dart_minilog/dart_minilog.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/input/game_keys.dart';
import 'package:voxone/util/game_data.dart';
import 'package:voxone/util/storage.dart' as storage;

final configuration = Configuration._();

class Configuration with HasGameData {
  Configuration._() {
    on_debug_change = (it) => _save_if(_data['debug'] != it);
    on_difficulty_change = (_) => _save_if(_data['difficulty'] != difficulty.name);
    on_game_pad_config_change = (_) => _save_if(_data['game_pad_config'] != game_pad_config.name);
    on_video_change = (_) => _save_if(_data['video'] != video.name);
  }

  void _save_if(bool changed) {
    if (changed) storage.save('configuration', this);
  }

  Future<void> load() async => await storage.load('configuration', this);

  // HasGameData

  var _data = <String, dynamic>{};

  @override
  void load_state(Map<String, dynamic> data) {
    _data = data;
    logInfo(data);
    debug = data['debug'] ?? debug;
    difficulty = Difficulty.values.firstWhere(
      (it) => it.name == data['difficulty'],
      orElse: () => difficulty,
    );
    game_pad_config = GamePadConfig.values.firstWhere(
      (it) => it.name == data['game_pad_config'],
      orElse: () => game_pad_config,
    );
    video = VideoMode.values.firstWhere(
      (it) => it.name == data['video'],
      orElse: () => video,
    );
  }

  @override
  GameData save_state(Map<String, dynamic> data) => data
    ..['debug'] = debug
    ..['difficulty'] = difficulty.name
    ..['game_pad_config'] = game_pad_config.name
    ..['video'] = video.name;
}

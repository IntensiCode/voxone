import 'package:collection/collection.dart';
import 'package:dart_extensions_methods/dart_extension_methods.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:kart/kart.dart';
import 'package:supercharged/supercharged.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/input/game_keys.dart';
import 'package:voxone/input/game_pads.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_data.dart';
import 'package:voxone/util/storage.dart' as storage;

final configuration = Configuration._();

class Configuration with HasGameData {
  Configuration._() {
    on_debug_change = (it) => _save_if(_data['debug'] != it);
    on_difficulty_change = (_) => _save_if(_data['difficulty'] != difficulty.name);
    on_video_change((_) => _save_if(_data['video'] != video.name));
    on_bg_anim_change((_) => _save_if(_data['bg_anim'] != bg_anim));
    on_skip_frames_change((_) => _save_if(_data['skip_frames'] != bg_anim));
  }

  void _save_if(bool changed) {
    if (changed) storage.save('configuration', this);
  }

  Future<void> load() async {
    await storage.load('configuration', this);
    logInfo(known_hw_mappings.entries.firstWhereOrNull((it) => it.value.deepEquals(hw_mapping))?.key ?? 'CUSTOM');
  }

  void save() => storage.save('configuration', this);

  // HasGameData

  var _data = <String, dynamic>{};

  @override
  void load_state(Map<String, dynamic> data) {
    _data = data;
    if (dev) logInfo(data);
    debug = data['debug'] ?? debug;
    difficulty = Difficulty.values.firstWhere(
      (it) => it.name == data['difficulty'],
      orElse: () => difficulty,
    );
    video = VideoMode.values.firstWhere(
      (it) => it.name == data['video'],
      orElse: () => video,
    );
    bg_anim = data['bg_anim'] ?? bg_anim;
    skip_frames = data['skip_frames'] ?? skip_frames;
    prefer_x_over_y = data['prefer_x_over_y'] ?? prefer_x_over_y;

    hw_mapping = (data['hw_mapping'] as Map<String, dynamic>? ?? {}).entries.mapNotNull((e) {
      final k = e?.key.toIntOrNull();
      if (k == null) return null;
      final v = GamePadControl.values.firstWhereOrNull((it) => it.name == e?.value);
      if (v == null) return null;
      return MapEntry(k, v);
    }).toMap();
  }

  @override
  GameData save_state(Map<String, dynamic> data) => data
    ..['debug'] = debug
    ..['difficulty'] = difficulty.name
    ..['prefer_x_over_y'] = prefer_x_over_y
    ..['hw_mapping'] = hw_mapping.map((k, v) => MapEntry(k.toString(), v.name))
    ..['skip_frames'] = skip_frames
    ..['bg_anim'] = bg_anim
    ..['video'] = video.name;
}

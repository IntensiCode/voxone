import 'dart:convert';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxone/util/game_data.dart';

final _prefs = SharedPreferences.getInstance();

late String storage_prefix;

extension on String {
  String get key => '${storage_prefix}_$this';
}

Future clear(String name) async {
  final preferences = await _prefs;
  preferences.remove(name.key);
  logVerbose('cleared $name data');
}

Future save(String name, HasGameData it) async => save_data(name, it.save_state({}));

Future load(String name, HasGameData it) async {
  final data = await load_data(name);
  if (data != null) it.load_state(data);
}

Future save_data(String name, GameData data) async {
  try {
    final preferences = await _prefs;
    preferences.setString(name.key, jsonEncode(data));
    logVerbose('saved $name data');
  } catch (it, trace) {
    logError('Failed to store $name: $it', trace);
  }
}

Future<GameData?> load_data(String name) async {
  try {
    final preferences = await _prefs;
    if (!preferences.containsKey(name.key)) {
      logVerbose('no data for $name');
      return null;
    }

    final json = preferences.getString(name.key);
    if (json == null) {
      logError('invalid data for $name');
      return null;
    }

    logInfo('loaded $name');
    logVerbose(json);
    return jsonDecode(json);
  } catch (it, trace) {
    logError('Failed to restore $name: $it', trace);
    return null;
  }
}

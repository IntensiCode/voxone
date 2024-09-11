import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:voxone/util/storage.dart';
import 'package:voxone/main_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  logLevel = kDebugMode ? LogLevel.debug : LogLevel.none;
  storage_prefix = 'voxone';
  runApp(GameWidget(game: MainGame()));
}

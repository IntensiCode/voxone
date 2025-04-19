import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:stardash/main_game.dart';
import 'package:stardash/util/storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  logLevel = kDebugMode ? LogLevel.debug : LogLevel.none;
  storage_prefix = 'stardash';
  runApp(GameWidget(game: MainGame()));
}

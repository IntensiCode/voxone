import 'package:flame/game.dart';

import 'common.dart';

enum Screen {
  audio_menu,
  credits,
  enter_hiscore,
  game,
  help,
  hiscore,
  options,
  splash,
  the_end,
  title,
}

class ShowScreen with Message {
  ShowScreen(this.screen);

  final Screen screen;
}

abstract interface class ScreenNavigation {
  void popScreen();

  void pushScreen(Screen screen);

  void showScreen(Screen screen, {bool skip_fade_out = false, bool skip_fade_in = false});
}

void popScreen() {
  final world = (game as FlameGame).world;
  (world as ScreenNavigation).popScreen();
}

void pushScreen(Screen it) {
  final world = (game as FlameGame).world;
  (world as ScreenNavigation).pushScreen(it);
}

void showScreen(Screen it, {bool skip_fade_out = false, bool skip_fade_in = false}) {
  final world = (game as FlameGame).world;
  (world as ScreenNavigation).showScreen(it, skip_fade_out: skip_fade_out, skip_fade_in: skip_fade_in);
}

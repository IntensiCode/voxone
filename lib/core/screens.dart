import 'common.dart';

enum Screen {
  stage1,
  stage2,
  stage3,
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
  final world = game.world;
  (world as ScreenNavigation).popScreen();
}

void pushScreen(Screen it) {
  final world = game.world;
  (world as ScreenNavigation).pushScreen(it);
}

void showScreen(Screen it, {bool skip_fade_out = false, bool skip_fade_in = false}) {
  final world = game.world;
  (world as ScreenNavigation).showScreen(it, skip_fade_out: skip_fade_out, skip_fade_in: skip_fade_in);
}

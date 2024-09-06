import '../../util/auto_dispose.dart';
import '../util/fonts.dart';
import 'components/military_text.dart';
import 'core/common.dart';
import 'core/screens.dart';
import 'game/soundboard.dart';
import 'util/shortcuts.dart';

class SplashScreen extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  final _text = '''
  An
  IntensiCode
  Presentation
  ~
  A
  PsychoCell
  Game
  ~
  Approved By
  The Military
  ''';

  @override
  void onMount() => onKey('<Space>', () => _leave());

  @override
  Future onLoad() async {
    if (dev) soundboard.fade_out_music();
    await add(MilitaryText(font: mini_font, font_scale: 2, text: _text, when_done: _leave));
  }

  void _leave() {
    showScreen(Screen.title, skip_fade_out: true, skip_fade_in: true);
    removeFromParent();
  }
}

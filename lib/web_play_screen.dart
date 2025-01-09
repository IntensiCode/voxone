import 'package:flame/components.dart';
import 'package:voxone/aural/audio_menu.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/ui/basic_menu.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/keys.dart';
import 'package:voxone/util/shortcuts.dart';

class WebPlayScreen extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  WebPlayScreen() {
    add(_keys);
  }

  final _keys = Keys();

  @override
  void onMount() => onKey('<Space>', () => _leave());

  @override
  void update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.start)) _leave();
  }

  @override
  onLoad() async {
    add(BasicMenu<AudioMenuEntry>(
      keys: _keys,
      button: atlas.sheetI('button_option.png', 1, 2),
      font: mini_font,
      onSelected: _selected,
      spacing: 10,
    )
      ..addEntry(AudioMenuEntry.master_volume, 'Start')
      ..addEntry(AudioMenuEntry.music_and_sound, 'Music & Sound')
      ..addEntry(AudioMenuEntry.music_only, 'Music Only')
      ..addEntry(AudioMenuEntry.sound_only, 'Sound Only')
      ..addEntry(AudioMenuEntry.silent_mode, 'Silent Mode')
      ..preselectEntry(AudioMenuEntry.master_volume)
      ..position.setValues(game_center.x, 64)
      ..anchor = Anchor.topCenter);
  }

  void _selected(AudioMenuEntry it) {
    switch (it) {
      case AudioMenuEntry.master_volume:
        _leave();
      case AudioMenuEntry.music_and_sound:
        audio.audio_mode = AudioMode.music_and_sound;
        _leave();
      case AudioMenuEntry.music_only:
        audio.audio_mode = AudioMode.music_only;
        _leave();
      case AudioMenuEntry.sound_only:
        audio.audio_mode = AudioMode.sound_only;
        _leave();
      case AudioMenuEntry.silent_mode:
        audio.audio_mode = AudioMode.silent;
        _leave();
      case _: // ignore
        _leave();
    }
  }

  void _leave() {
    fadeOutDeep();
    removed.then((_) => showScreen(Screen.title));
  }
}

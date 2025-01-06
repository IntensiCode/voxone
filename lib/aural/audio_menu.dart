import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/aural/volume_component.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/ui/basic_menu.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/ui/soft_keys.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';

enum AudioMenuEntry {
  music_and_sound,
  music_only,
  sound_only,
  silent_mode,
  brick_notes,
}

class AudioMenu extends GameScriptComponent {
  final bool show_back;

  AudioMenu({required this.show_back});

  late final BasicMenu menu;

  // late final BasicMenuButton brick_notes;

  @override
  onLoad() async {
    // add(await sprite_comp('background.png'));
    await add(Space());

    fontSelect(tiny_font, scale: 2);
    textXY('Audio Mode', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);

    // bg_nine_patch: atlas.image('button_plain.png'),
    final button = atlas.sprite('button_plain.png');
    add(_master = VolumeComponent(
      bg_nine_patch: button,
      label: 'Master Volume - / +',
      position: Vector2(16, 46),
      anchor: Anchor.topLeft,
      size: Vector2(96 * 2, 32 * 2),
      key_down: '-',
      key_up: '+',
      change: (volume) => soundboard.master = volume,
      volume: () => soundboard.master,
    ));
    add(_music = VolumeComponent(
      bg_nine_patch: button,
      label: 'Music Volume [ / ]',
      position: Vector2(16, 46 + 34 * 2),
      anchor: Anchor.topLeft,
      size: Vector2(96 * 2, 32 * 2),
      key_down: '[',
      key_up: ']',
      change: (volume) => soundboard.music = volume,
      volume: () => soundboard.music,
    ));
    add(_sound = VolumeComponent(
      bg_nine_patch: button,
      label: 'Sound Volume { / }',
      position: Vector2(16, 46 + 34 * 4),
      anchor: Anchor.topLeft,
      size: Vector2(96 * 2, 32 * 2),
      key_down: '{',
      key_up: '}',
      change: (volume) {
        soundboard.sound = volume;
        _make_sound();
      },
      volume: () => soundboard.sound,
    ));

    final buttonSheet = atlas.sheetI('button_option.png', 1, 2);
    menu = added(BasicMenu<AudioMenuEntry>(
      button: buttonSheet,
      font: mini_font,
      onSelected: _selected,
      spacing: 2,
      fixed_position: Vector2(game_width - 16, 56),
      fixed_anchor: Anchor.topRight,
    )
      ..addEntry(AudioMenuEntry.music_and_sound, 'Music & Sound')
      ..addEntry(AudioMenuEntry.music_only, 'Music Only')
      ..addEntry(AudioMenuEntry.sound_only, 'Sound Only')
      ..addEntry(AudioMenuEntry.silent_mode, 'Silent Mode'));

    // brick_notes = menu.addEntry(AudioMenuEntry.brick_notes, 'Brick Notes', anchor: Anchor.centerLeft);
    // brick_notes.checked = soundboard.brick_notes;

    menu.position.setFrom(game_center);
    menu.anchor = Anchor.center;

    menu.onPreselected = (it) => _preselected(it);

    if (show_back) softkeys('Back', null, (_) => popScreen());

    logInfo('initial audio mode: ${soundboard.audio_mode}');
    final preselected = switch (soundboard.audio_mode) {
      AudioMode.music_and_sound => AudioMenuEntry.music_and_sound,
      AudioMode.music_only => AudioMenuEntry.music_only,
      AudioMode.sound_only => AudioMenuEntry.sound_only,
      AudioMode.silent => AudioMenuEntry.silent_mode,
    };
    menu.preselectEntry(preselected);
    _preselected(preselected);

    // if (kIsWeb) {
    //   add(FlowText(
    //     text: 'Brick Notes may degrade performance. Try if it works for you!',
    //     font: tiny_font,
    //     position: Vector2(112, 174),
    //     size: Vector2(192, 24),
    //     insets: Vector2(6, 6),
    //   ));
    // }
  }

  late final VolumeComponent _master;
  late final VolumeComponent _music;
  late final VolumeComponent _sound;

  _selected(AudioMenuEntry it) {
    // if (it == AudioMenuEntry.brick_notes) {
    //   soundboard.brick_notes = !soundboard.brick_notes;
    //   brick_notes.checked = soundboard.brick_notes;
    // }
    return menu.preselectEntry(it);
  }

  _preselected(AudioMenuEntry? it) {
    logVerbose('audio menu preselected: $it');
    switch (it) {
      case AudioMenuEntry.music_and_sound:
        soundboard.audio_mode = AudioMode.music_and_sound;
        _master.isVisible = true;
        _music.isVisible = true;
        _sound.isVisible = true;
        _make_sound();
      case AudioMenuEntry.music_only:
        soundboard.audio_mode = AudioMode.music_only;
        _master.isVisible = true;
        _music.isVisible = true;
        _sound.isVisible = false;
      case AudioMenuEntry.sound_only:
        soundboard.audio_mode = AudioMode.sound_only;
        _master.isVisible = true;
        _music.isVisible = false;
        _sound.isVisible = true;
        _make_sound();
      case AudioMenuEntry.brick_notes:
        break;
      case AudioMenuEntry.silent_mode:
        soundboard.audio_mode = AudioMode.silent;
        _master.isVisible = false;
        _music.isVisible = false;
        _sound.isVisible = false;
      case null:
        break;
    }
  }

  int _last_sound_at = 0;

  void _make_sound() {
    final now = DateTime.timestamp().millisecondsSinceEpoch;
    if (_last_sound_at + 100 > now) return;
    _last_sound_at = now;
    final which = Sound.values.random().name;
    soundboard.play_one_shot_sample('sound/$which.ogg');
  }
}

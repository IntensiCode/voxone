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
import 'package:voxone/util/keys.dart';

enum AudioMenuEntry {
  music_and_sound,
  music_only,
  sound_only,
  silent_mode,
  brick_notes,
}

class AudioMenu extends GameScriptComponent {
  final _keys = Keys();

  final bool show_back;

  AudioMenu({required this.show_back});

  late final BasicMenu menu;

  @override
  onLoad() {
    add(_keys);
    add(Space());

    fontSelect(tiny_font, scale: 2);
    textXY('Audio Mode', game_center.x, 20, scale: 2, anchor: Anchor.topCenter);

    _add_volume_controls();

    final buttonSheet = atlas.sheetI('button_option.png', 1, 2);
    menu = added(BasicMenu<AudioMenuEntry>(
      keys: _keys,
      button: buttonSheet,
      font: mini_font,
      onSelected: _selected,
      spacing: 2,
    )
      ..addEntry(AudioMenuEntry.music_and_sound, 'Music & Sound')
      ..addEntry(AudioMenuEntry.music_only, 'Music Only')
      ..addEntry(AudioMenuEntry.sound_only, 'Sound Only')
      ..addEntry(AudioMenuEntry.silent_mode, 'Silent Mode'));

    menu.position.setFrom(game_center);
    menu.anchor = Anchor.bottomCenter;

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
  }

  void _add_volume_controls() {
    void change_master(double volume) => soundboard.master = volume;
    double read_master() => soundboard.master;
    void change_music(double volume) => soundboard.music = volume;
    double read_music() => soundboard.music;
    void change_sound(double volume) => soundboard.sound = volume;
    double read_sound() => soundboard.sound;

    final pos_y = 320.0;
    final positions = [Vector2(64, pos_y), Vector2(game_center.x, pos_y), Vector2(game_width - 64, pos_y)];

    add(_master = _volume_control('Master Volume - / +', '-', '+',
        position: positions[0], anchor: Anchor.topLeft, change: change_master, volume: read_master));
    add(_music = _volume_control('Music Volume [ / ]', '[', ']',
        position: positions[1], anchor: Anchor.topCenter, change: change_music, volume: read_music));
    add(_sound = _volume_control('Sound Volume { / }', '{', '}',
        position: positions[2], anchor: Anchor.topRight, change: change_sound, volume: read_sound));
  }

  late final VolumeComponent _master;
  late final VolumeComponent _music;
  late final VolumeComponent _sound;

  _selected(AudioMenuEntry it) => menu.preselectEntry(it);

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
    final which = (Sound.values - [Sound.incoming]).random().name;
    soundboard.play_one_shot_sample('sound/$which.ogg');
  }

  VolumeComponent _volume_control(
    String label,
    String increase_shortcut,
    String decrease_shortcut, {
    required Vector2 position,
    Anchor? anchor,
    Vector2? size,
    required double Function() volume,
    required void Function(double) change,
  }) =>
      VolumeComponent(
        bg_nine_patch: atlas.sprite('button_plain.png'),
        label: label,
        position: position,
        anchor: anchor ?? Anchor.topLeft,
        size: size ?? Vector2(96 * 2, 32 * 2),
        key_down: decrease_shortcut,
        key_up: increase_shortcut,
        change: change,
        volume: volume,
      );
}

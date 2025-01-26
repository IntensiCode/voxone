import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/game/shared/voxel_entity.dart';
import 'package:voxone/input/keys.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/ui/basic_menu.dart';
import 'package:voxone/ui/flow_text.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/messaging.dart';

enum _TitleButtons {
  credits,
  audio,
  video,
  controls,
  play,
}

final _credits = [
  'Music by suno.com',
  'Voxel Models by maxparata.itch.io',
  'Star Nest Shader by Pablo Roman Andrioli',
];

class TitleScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  static _TitleButtons? _preselected = _TitleButtons.play;

  final _shadows = Shadows()..isVisible = false;
  final _keys = Keys();

  BitmapText? _audio;
  BitmapText? _video;
  BitmapText? _difficulty;

  @override
  void onLoad() {
    add(_keys);
    add(space);
    add(_shadows);
    add(_TitleShip());

    textXY('VOXONE', 16, 12, anchor: Anchor.topLeft, scale: 4);
    textXY('INSANITY FIGHT 2', 16, 50, anchor: Anchor.topLeft, scale: 1);

    for (final (idx, it) in _credits.reversed.indexed) {
      textXY(it, 784, 466 - idx * 10, anchor: Anchor.bottomRight, scale: 1);
    }

    textXY('< Audio Mode >', 280, 356, anchor: Anchor.bottomCenter, scale: 1);
    _audio = textXY(audio.guess_audio_mode.label, 280, 368, anchor: Anchor.bottomCenter, scale: 1);

    textXY('< Video Mode >', 280, 480 - 76 - 16, anchor: Anchor.bottomCenter, scale: 1);
    _video = textXY(video.name, 280, 480 - 76 - 5, anchor: Anchor.bottomCenter, scale: 1);

    textXY('< Difficulty >', 280, 480 - 28, anchor: Anchor.bottomCenter, scale: 1);
    _difficulty = textXY(difficulty.name, 280, 480 - 16, anchor: Anchor.bottomCenter, scale: 1);

    final menu = added(BasicMenu<_TitleButtons>(
      keys: _keys,
      font: mini_font,
      onSelected: _selected,
      spacing: 8,
      fixed_position: Vector2(16, game_height - 8),
      fixed_anchor: Anchor.bottomLeft,
    ));

    menu.addEntry(_TitleButtons.credits, 'Credits');
    menu.addEntry(_TitleButtons.audio, 'Audio');
    menu.addEntry(_TitleButtons.video, 'Video');
    menu.addEntry(_TitleButtons.controls, 'Controls');
    menu.addEntry(_TitleButtons.play, 'Play');
    menu.preselectEntry(_preselected ?? _TitleButtons.play);

    menu.onPreselected = (id) => _preselected = id;

    final cheats = '''
    Cheat Mode Active
    >
    All Primary Weapons Available
    >
    [ :: Recharge All Secondary Weapons
    ] :: Boost Player Strength
    { :: Repair Player
    } :: Toggle Indestructible 
    >
    Delete :: Destroy Player
    Insert :: Destroy All Enemies
    Backspace :: Remove All Enemies
    >
    1 - 5 :: Jump to Stage (NYI)
    ''';
    add(_cheats = FlowText(
      text: cheats,
      background: atlas.sprite('button_plain.png'),
      font: mini_font,
      insets: Vector2(9, 9),
      position: Vector2(game_width - 320 - 16, 16),
      anchor: Anchor.topLeft,
      size: Vector2(320, 176),
    ));
    _cheats.isVisible = cheat;
  }

  late FlowText _cheats;

  void _selected(_TitleButtons id) {
    _preselected = id;
    switch (id) {
      case _TitleButtons.credits:
        showScreen(Screen.credits);
        break;
      case _TitleButtons.audio:
        pushScreen(Screen.audio);
        break;
      case _TitleButtons.video:
        pushScreen(Screen.video);
        break;
      case _TitleButtons.controls:
        pushScreen(Screen.controls);
        break;
      case _TitleButtons.play:
        showScreen(Screen.stage1);
        break;
    }
  }

  String _cheat = '';

  @override
  void onMount() {
    super.onMount();
    onKeys(['t', 'f', 'd', 'j'], (it) {
      if (it == 't' || it == 'f' || it == 'd' || it == 'j') {
        if (it == 'd' && !_cheat.endsWith('tf')) _keys.onPressed(GameKey.right);
        if (it == 'j' && !_cheat.endsWith('tfd')) _keys.onPressed(GameKey.down);
        _check_cheat(it);
      }
    });
  }

  void _check_cheat(String add) {
    _cheat += add;
    while (_cheat.length > 4) {
      _cheat = _cheat.substring(1);
    }
    if (_cheat == 'tfdj') {
      cheat = !cheat;
      logInfo('cheat mode $cheat');
      _cheat = '';
      _cheats.isVisible = cheat;
      sendMessage(ToggleCheatMode());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.start)) {
      pushScreen(Screen.stage1);
    }
    if (_keys.check_and_consume(GameKey.left)) {
      if (_preselected == _TitleButtons.audio) _change_audio_mode(-1);
      if (_preselected == _TitleButtons.video) _change_video_mode(-1);
      if (_preselected == _TitleButtons.play) _change_difficulty(-1);
    }
    if (_keys.check_and_consume(GameKey.right)) {
      if (_preselected == _TitleButtons.audio) _change_audio_mode(1);
      if (_preselected == _TitleButtons.video) _change_video_mode(1);
      if (_preselected == _TitleButtons.play) _change_difficulty(1);
    }
  }

  void _change_audio_mode(int add) {
    final values = AudioMode.values;
    final index = (values.indexOf(audio.guess_audio_mode) + add) % values.length;
    audio.audio_mode = values[index];
    _audio?.text = audio.guess_audio_mode.label;
    _audio?.fadeInDeep();
  }

  void _change_video_mode(int add) {
    final values = VideoMode.values;
    final index = (values.indexOf(video) + add) % values.length;
    video = values[index];
    _video?.text = video.name;
    _video?.fadeInDeep();
  }

  void _change_difficulty(int add) {
    final values = Difficulty.values;
    final index = (values.indexOf(difficulty) + add + values.length) % values.length;
    difficulty = values[index];
    _difficulty?.text = difficulty.name;
    _difficulty?.fadeInDeep();
  }
}

class _TitleShip extends VoxelEntity {
  _TitleShip() {
    set_sprite_source(atlas.sprite('entities/dual_striker.png'), 16);
  }

  double _time = 0;

  @override
  onLoad() async {
    super.onLoad();

    force_render = !dev;

    scale_x = 1.4;
    scale_y = 4.5;
    scale_z = 1.4;
    size.setAll(256);
    position.setValues(400, 350);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
    // _entity.scale.setAll(1 + sin(_time / 2) / 4);
    // rot_x = -0.00;
    rot_y = sin(_time) * 1.75;
    rot_z = _time;
    position.setValues(400 + cos(pi + _time) * 200, 250);
  }
}

import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/game/shared/video_mode.dart';
import 'package:voxone/input/keys.dart';
import 'package:voxone/input/shortcuts.dart';
import 'package:voxone/ui/basic_menu.dart';
import 'package:voxone/ui/flow_text.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/bitmap_text.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/stacked_sprite.dart';

enum _TitleButtons {
  audio,
  video,
  controls,
  play,
}

final _credits = [
  'A Psychocell Game',
  'An IntensiCode Production',
  'Made with Flame Engine',
  'Powered by Flutter',
  '',
  'Music by suno.com',
  'Voice Samples by elevenlabs.io',
  'Voxel Models by maxparata.itch.io',
  'Star Nest Shader by Pablo Roman Andrioli',
  '2D Art by itch.io',
  '',
  'Code by The.French.DJ   [IntensiCode]',
];

class TitleScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  static _TitleButtons? _preselected;

  final _shadows = Shadows()..isVisible = false;
  final _keys = Keys();

  BitmapText? _difficulty;

  @override
  onLoad() {
    add(_keys);
    add(space);
    add(_shadows);
    add(_TitleShip(_shadows));

    textXY('VOXONE', 16, 12, anchor: Anchor.topLeft, scale: 4);
    textXY('INSANITY FIGHT 2', 16, 50, anchor: Anchor.topLeft, scale: 1);

    for (final (idx, it) in _credits.reversed.indexed) {
      textXY(it, 784, 464 - idx * 10, anchor: Anchor.bottomRight, scale: 1);
    }

    textXY('< Difficulty >', 280, 480 - 30, anchor: Anchor.bottomCenter, scale: 1);
    _difficulty = textXY(difficulty.name, 280, 480 - 18, anchor: Anchor.bottomCenter, scale: 1);

    textXY(video.name, 280, 480 - 76, anchor: Anchor.bottomCenter, scale: 1);

    final menu = added(BasicMenu<_TitleButtons>(
      keys: _keys,
      button: atlas.sheetI('button_option.png', 1, 2),
      font: mini_font,
      onSelected: _selected,
      spacing: 2,
      fixed_position: Vector2(16, game_height - 16),
      fixed_anchor: Anchor.bottomLeft,
    )
      ..addEntry(_TitleButtons.audio, 'Audio')
      ..addEntry(_TitleButtons.video, 'Video')
      ..addEntry(_TitleButtons.controls, 'Controls')
      ..addEntry(_TitleButtons.play, 'Play')
      ..preselectEntry(_preselected ?? _TitleButtons.play));

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

    onKey('<Left>', () => _change_difficulty(-1));
    onKey('<Right>', () => _change_difficulty(1));
    onKey('<', () => _change_difficulty(-1));
    onKey('>', () => _change_difficulty(1));

    onKey('t', () => _check_cheat('t'));
    onKey('f', () => _check_cheat('f'));
    onKey('d', () => _check_cheat('d'));
    onKey('j', () => _check_cheat('j'));
  }

  void _change_difficulty(int add) {
    final values = Difficulty.values;
    final index = (values.indexOf(difficulty) + add + values.length) % values.length;
    difficulty = values[index];
    _difficulty?.removeFromParent();
    _difficulty = textXY(difficulty.name, 280, 480 - 18, anchor: Anchor.bottomCenter, scale: 1);
    _difficulty?.fadeInDeep();
    sendMessage(UpdateDifficulty());
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
    if (_keys.check_and_consume(GameKey.start)) pushScreen(Screen.stage1);

    if (_keys.check_and_consume(GameKey.left)) _change_difficulty(-1);
    if (_keys.check_and_consume(GameKey.right)) _change_difficulty(1);
  }

  @override
  void renderTree(Canvas canvas) {
    StackedSprite.render_count = 0;
    super.renderTree(canvas);
  }
}

class _TitleShip extends Component {
  _TitleShip(this._shadows);

  final Shadows _shadows;

  late final StackedEntity _entity;

  double _time = 0;

  @override
  onLoad() async {
    super.onLoad();

    _entity = StackedEntity('entities/dual_striker.png', 16, _shadows);
    _entity.sprite.force_render = true;

    _entity.scale_x = 1.4;
    _entity.scale_y = 4.5;
    _entity.scale_z = 1.4;
    _entity.scale.setAll(1);
    _entity.size.setAll(256);
    _entity.position.setValues(400, 350);

    add(_entity);
  }

  @override
  void update(double dt) {
    _time += dt;
    // _entity.scale.setAll(1 + sin(_time / 2) / 4);
    _entity.rot_x = -0.00;
    _entity.rot_y = sin(_time) * 1.75;
    _entity.rot_z = _time;
    _entity.position.setValues(400 + cos(pi + _time) * 200, 250);
  }
}

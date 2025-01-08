import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/background/space.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/screens.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/ui/basic_menu.dart';
import 'package:voxone/ui/fonts.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/keys.dart';
import 'package:voxone/util/shortcuts.dart';

enum _TitleButtons {
  audio,
  controls,
  play,
}

class TitleScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  static _TitleButtons? _preselected;

  final _shadows = Shadows()..isVisible = false;
  final _keys = Keys();

  @override
  onLoad() {
    add(_keys);
    add(Space());
    add(_shadows);
    add(_TitleShip(_shadows));

    textXY('VOXONE', 16, 12, anchor: Anchor.topLeft, scale: 4);
    textXY('INSANITY FIGHT 2', 16, 50, anchor: Anchor.topLeft, scale: 1);

    textXY('Voxel Models by maxparata.itch.io', 800 - 16, 450, anchor: Anchor.topRight, scale: 1);
    textXY('Star Nest Shader by Pablo Roman Andrioli', 800 - 16, 460, anchor: Anchor.topRight, scale: 1);

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
      ..addEntry(_TitleButtons.controls, 'Controls')
      ..addEntry(_TitleButtons.play, 'Play')
      ..preselectEntry(_preselected ?? _TitleButtons.play));

    menu.onPreselected = (id) => _preselected = id;
  }

  void _selected(_TitleButtons id) {
    _preselected = id;
    switch (id) {
      case _TitleButtons.audio:
        pushScreen(Screen.audio);
        break;
      case _TitleButtons.controls:
        pushScreen(Screen.controls);
        break;
      case _TitleButtons.play:
        showScreen(Screen.stage1);
        break;
    }
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

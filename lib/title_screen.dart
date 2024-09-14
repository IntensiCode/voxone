import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/core/screens.dart';
import 'package:voxone/game/shadows.dart';
import 'package:voxone/game/space.dart';
import 'package:voxone/game/stacked_entity.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/shortcuts.dart';

class TitleScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  final _shadows = Shadows()..isVisible = false;

  @override
  onLoad() async {
    super.onLoad();

    await add(Space());
    await add(_shadows);
    await add(_TitleShip(_shadows));

    textXY('VOXONE', 16, 12, anchor: Anchor.topLeft, scale: 4);
    textXY('A Flutter Flame Experiment', 16, 50, anchor: Anchor.topLeft, scale: 1);

    textXY('Controls', 16, 350, anchor: Anchor.topLeft, scale: 1);
    textXY('Arrow Keys Left / Right - Strafe', 16, 360, anchor: Anchor.topLeft, scale: 1);
    textXY('Space - Primary Fire', 16, 370, anchor: Anchor.topLeft, scale: 1);
    textXY('Control - Secondary Fire', 16, 380, anchor: Anchor.topLeft, scale: 1);
    textXY('Shift - Roll', 16, 390, anchor: Anchor.topLeft, scale: 1);

    // textXY('Esc / Control-t - Back To Title', 16, 410, anchor: Anchor.topLeft, scale: 1);
    // textXY('Control-m - Toggle Mute Sound', 16, 420, anchor: Anchor.topLeft, scale: 1);
    // textXY('Control-p - Toggle Pause Game', 16, 430, anchor: Anchor.topLeft, scale: 1);
    // textXY('Control-v - Toggle Full Pixelate', 16, 440, anchor: Anchor.topLeft, scale: 1);

    textXY('Press Space To Play', 16, 460, anchor: Anchor.topLeft, scale: 1);

    textXY('Voxel Models by maxparata.itch.io', 800 - 16, 450, anchor: Anchor.topRight, scale: 1);
    textXY('Star Nest Shader by Pablo Roman Andrioli', 800 - 16, 460, anchor: Anchor.topRight, scale: 1);
  }

  @override
  void onMount() {
    super.onMount();

    onKey('<Space>', () => showScreen(Screen.stage1));
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
    _entity.scale.setAll(0.3);
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

import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/plasma_shot.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class TriplePlasmaGun extends Component with HasContext, PrimaryWeapon {
  TriplePlasmaGun(this._player);

  final Player _player;

  final _projectiles = ComponentRecycler(() => PlasmaShot());

  double _cool_down = 0;

  @override
  String get display_name => 'Triple Plasma';

  @override
  Sprite get icon => extras.icon_for(ExtraId.triple_plasma);

  void boost_power() => PlasmaShot.power_boost = min(5, PlasmaShot.power_boost + 0.25);

  @override
  onLoad() => PlasmaShot.power_boost = 1;

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.35;

      final count = 2 + PlasmaShot.power_boost.round();

      for (var i = 0; i < count; i++) {
        stage.add(_projectiles.acquire()
          ..reset(_player.position)
          ..change_direction(pi / 48 * (i - count / 2)));
      }

      audio.play(Sound.shot, volume_factor: 0.5);
    }
  }
}

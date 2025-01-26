import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/background/ground.dart';
import 'package:voxone/game/player/projectiles/plasma_shot.dart';
import 'package:voxone/game/shared/difficulty.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/fake_three_dee.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class PlasmaGun extends Component with HasContext, PrimaryWeapon {
  PlasmaGun(this._player);

  final Player _player;

  late bool _over_ground;

  late final _projectiles = ComponentRecycler(() => PlasmaShot(over_ground: _over_ground));

  double _cool_down = 0;

  @override
  String get display_name => 'Plasma Gun';

  @override
  Sprite get icon => extras.icon_for(ExtraId.plasma_gun);

  void boost_power() => PlasmaShot.power_boost = min(5, PlasmaShot.power_boost + 0.25);

  @override
  onLoad() {
    _over_ground = stage.children.firstWhereOrNull((it) => it is Ground) != null;
    PlasmaShot.power_boost = 1;
  }

  @override
  void update(double dt) {
    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    if (keys.a_button) {
      _cool_down += 0.35;

      final bonus = switch (difficulty) {
        Difficulty.easy => 2,
        Difficulty.normal => 1,
        Difficulty.hard => 0,
      };
      final count = 2 + PlasmaShot.power_boost.round() + bonus;
      for (var i = 0; i < count; i++) {
        final d = pi / 48 * (i - (count - 1) / 2);
        stage.add(_projectiles.acquire()
          ..reset(_player as FakeThreeDee)
          ..speed_buff = -d.abs() * 250
          ..change_direction(d));
      }

      audio.play(Sound.shot, volume_factor: 0.5);
    }
  }
}

import 'dart:math';

import 'package:flame/components.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/game/player/projectiles/bomb.dart';
import 'package:stardash/game/player/projectiles/cluster_bomb.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';

class ClusterBombCannon extends Component with HasContext, SecondaryWeapon {
  ClusterBombCannon(this._player, Function(SecondaryWeapon) on_fired) {
    super.on_fired = on_fired;
  }

  final Player _player;

  late final _primary = ComponentRecycler(() => ClusterBomb(_emit_bombs))..precreate(8);
  late final _secondary = ComponentRecycler(() => Bomb())..precreate(128);

  @override
  String get display_name => 'Cluster Bomb Cannon';

  @override
  Sprite get icon => extras.icon_for(ExtraId.cluster_bomb);

  @override
  void do_fire() {
    stage.add(_primary.acquire()..reset(_player as FakeThreeDee));
    audio.play(Sound.swirl, volume_factor: 0.25);
  }

  _emit_bombs(FakeThreeDee origin) {
    audio.play(Sound.emit, volume_factor: 0.25);
    final count = 24;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * pi / count;
      final offset = Vector2(cos(angle), sin(angle)) * 5;
      stage.add(_secondary.acquire()
        ..reset(origin)
        ..position.add(offset)
        ..set_direction(offset));
    }
  }
}

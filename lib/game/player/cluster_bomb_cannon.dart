import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/bomb.dart';
import 'package:voxone/game/player/cluster_bomb.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class ClusterBombCannon extends Component with HasContext, SecondaryWeapon {
  ClusterBombCannon(this._player, this._on_fired);

  final Player _player;
  final void Function(SecondaryWeapon) _on_fired;

  late final _primary = ComponentRecycler(() => ClusterBomb(_emit_bombs));
  late final _secondary = ComponentRecycler(() => Bomb());

  @override
  String get display_name => 'Cluster Bomb Cannon';

  @override
  Sprite get icon => extras.icon_for(ExtraId.cluster_bomb);

  @override
  void update(double dt) {
    if (cooldown > 0) {
      cooldown = max(0, cooldown - dt);
      return;
    }

    if (keys.x_button) {
      cooldown += cooldown_time;
      stage.add(_primary.acquire()..reset(_player.position));
      audio.play(Sound.shot, volume_factor: 0.5);
      _on_fired(this);
    }
  }

  _emit_bombs(Vector2 origin) {
    final count = 24;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * pi / count;
      final offset = Vector2(cos(angle), sin(angle)) * 5;
      stage.add(_secondary.acquire()
        ..reset(origin + offset)
        ..set_direction(offset));
    }
  }
}

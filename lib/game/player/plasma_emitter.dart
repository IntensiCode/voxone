import 'dart:math';

import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/plasma_blob.dart';
import 'package:voxone/game/player/plasma_ring.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class PlasmaEmitter extends Component with HasContext, SecondaryWeapon {
  PlasmaEmitter(this._player, this._on_fired);

  final Player _player;
  final void Function(SecondaryWeapon) _on_fired;

  late final _blobs = ComponentRecycler(() => PlasmaBlob(_emit_plasma_ring));
  late final _rings = ComponentRecycler(() => PlasmaRing());

  @override
  String get display_name => 'Plasma Emitter';

  @override
  Sprite get icon => extras.icon_for(ExtraId.plasma_ring);

  @override
  void update(double dt) {
    if (cooldown > 0) {
      cooldown = max(0, cooldown - dt);
      return;
    }

    if (keys.x_button) {
      cooldown += cooldown_time;
      stage.add(_blobs.acquire()..reset(_player.position));
      audio.play(Sound.acid_blast, volume_factor: 0.5);
      _on_fired(this);
    }
  }

  _emit_plasma_ring(Vector2 origin) => stage.add(_rings.acquire()..reset(origin));
}

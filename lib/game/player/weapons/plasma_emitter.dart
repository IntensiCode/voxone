import 'package:flame/components.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/game/player/projectiles/plasma_blob.dart';
import 'package:stardash/game/player/projectiles/plasma_ring.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';

class PlasmaEmitter extends Component with HasContext, SecondaryWeapon {
  PlasmaEmitter(this._player, Function(SecondaryWeapon) on_fired) {
    super.on_fired = on_fired;
  }

  final Player _player;

  late final _blobs = ComponentRecycler(() => PlasmaBlob(_emit_plasma_ring))..precreate(8);
  late final _rings = ComponentRecycler(() => PlasmaRing())..precreate(8);

  @override
  String get display_name => 'Plasma Emitter';

  @override
  Sprite get icon => extras.icon_for(ExtraId.plasma_ring);

  @override
  void do_fire() {
    stage.add(_blobs.acquire()..reset(_player as FakeThreeDee));
    audio.play(Sound.acid_blast, volume_factor: 0.5);
  }

  _emit_plasma_ring(Vector2 origin, double fake_height) => stage.add(_rings.acquire()..reset(origin, fake_height));
}

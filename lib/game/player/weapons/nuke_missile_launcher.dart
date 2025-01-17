import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/player/projectiles/nuke.dart';
import 'package:voxone/game/player/projectiles/nuke_missile.dart';
import 'package:voxone/game/shared/decals.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/extras.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/traits.dart';
import 'package:voxone/util/component_recycler.dart';

class NukeMissileLauncher extends Component with HasContext, SecondaryWeapon {
  NukeMissileLauncher(this._player, Function(SecondaryWeapon) on_fired) {
    super.on_fired = on_fired;
  }

  final Player _player;

  late final _missiles = ComponentRecycler(() => NukeMissile(decals, _emit_nuke));
  late final _nukes = ComponentRecycler(() => Nuke());

  @override
  double get cooldown_time => 4;

  @override
  String get display_name => 'Nuke Missile';

  @override
  Sprite get icon => extras.icon_for(ExtraId.nuke_missile);

  @override
  void do_fire() {
    stage.add(_missiles.acquire()..reset(_player.position));
    audio.play(Sound.acid_blast, volume_factor: 0.5);
  }

  _emit_nuke(Vector2 origin) => stage.add(_nukes.acquire()..reset(origin));
}

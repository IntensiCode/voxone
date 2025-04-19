import 'package:flame/components.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/game/player/projectiles/nuke.dart';
import 'package:stardash/game/player/projectiles/nuke_missile.dart';
import 'package:stardash/game/shared/decals.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/fake_three_dee.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';

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
    stage.add(_missiles.acquire()..reset(_player as FakeThreeDee));
    audio.play(Sound.acid_blast, volume_factor: 0.5);
  }

  _emit_nuke(FakeThreeDee origin) => stage.add(_nukes.acquire()..reset(origin));
}

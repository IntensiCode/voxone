import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/core/atlas.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/stage1/homing_bomb.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/random.dart';

class HomingLauncher extends Component with HasContext {
  HomingLauncher(this.source);

  final Marauder source;

  double _cool_down = 3 + rng.nextDouble();

  final _projectiles = ComponentRecycler(() => HomingBomb());

  @override
  onLoad() => HomingBomb.sheet = atlas.sheetI('nuke_core.png', 8, 1);

  @override
  void update(double dt) {
    if (source.state == MarauderState.exploding) removeFromParent();
    if (source.state == MarauderState.defeated) removeFromParent();
    if (source.state == MarauderState.left) removeFromParent();
    if (source.state != MarauderState.active) return;

    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    _cool_down += 5.4 + rng.nextDoubleLimit(0.9);

    final it = _projectiles.acquire()..reset();
    it.position.setFrom(source.position);
    it.x -= 25;
    it.y += 25 / 4;
    stage.add(it);

    audio.play(Sound.acid_blast, volume_factor: 0.5);
  }
}

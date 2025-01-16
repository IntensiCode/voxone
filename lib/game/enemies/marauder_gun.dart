import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/enemies/marauder.dart';
import 'package:voxone/game/enemies/marauder_shot.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/random.dart';

class MarauderGun extends Component with HasContext {
  MarauderGun(this.source);

  final Marauder source;

  double _cool_down = rng.nextDouble();

  final _projectiles = ComponentRecycler(() => MarauderShot());

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

    _cool_down += 0.4 + rng.nextDoubleLimit(0.9);

    final it = _projectiles.acquire();
    it.position.setFrom(source.position);
    it.x -= 25;
    it.y += 25 / 4;
    stage.add(it);

    audio.play(Sound.shot, volume_factor: 0.5);
  }
}

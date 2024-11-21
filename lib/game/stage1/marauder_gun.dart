import 'package:flame/components.dart';
import 'package:voxone/game/context.dart';
import 'package:voxone/game/stage1/sweeping_marauder.dart';
import 'package:voxone/game/stage1/marauder_shot.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';

class MarauderGun extends Component with Context {
  MarauderGun(this.source);

  final SweepingMarauder source;

  double _cool_down = rng.nextDouble();

  @override
  void update(double dt) {
    if (source.state == SweepingMarauderState.exploding) removeFromParent();
    if (source.state == SweepingMarauderState.defeated) removeFromParent();
    if (source.state == SweepingMarauderState.left) removeFromParent();
    if (source.state != SweepingMarauderState.active) return;

    if (_cool_down > 0) {
      _cool_down -= dt;
      return;
    }

    _cool_down += 0.4 + rng.nextDoubleLimit(0.9);

    final it = MarauderShot();
    it.position.setFrom(source.position);
    it.x -= 25;
    it.y += 25 / 4;
    stage.add(it);
  }
}

import 'package:flame/components.dart';
import 'package:voxone/aural/soundboard.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/shared/marauder_shot.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';

class MarauderGun extends Component with HasContext {
  MarauderGun(this.source);

  final Marauder source;

  double _cool_down = rng.nextDouble();

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

    final it = MarauderShot();
    it.position.setFrom(source.position);
    it.x -= 25;
    it.y += 25 / 4;
    stage.add(it);

    soundboard.play(Sound.shot, volume_factor: 0.5);
  }
}

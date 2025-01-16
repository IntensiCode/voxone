import 'package:flame/components.dart';
import 'package:voxone/aural/audio_system.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/game/enemies/marauder.dart';
import 'package:voxone/game/enemies/marauder_shot.dart';
import 'package:voxone/util/component_recycler.dart';
import 'package:voxone/util/random.dart';

class MarauderPulseGun extends Component with HasContext {
  MarauderPulseGun(this.source);

  final Marauder source;

  double _cool_down = rng.nextDouble();

  int _fire_salvo = 5;

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

    if (_fire_salvo > 0) {
      if (_fire_salvo == 5) {
        audio.play(Sound.shot, volume_factor: 0.5);
      }
      _cool_down += 0.1;

      _fire_salvo--;

      final it = _projectiles.acquire();
      it.position.setFrom(source.position);
      it.x -= 25;
      it.y += 25 / 4;
      stage.add(it);

    } else {
      _cool_down += 1.4 + rng.nextDoubleLimit(0.1);
      _fire_salvo = 5;
    }
  }
}

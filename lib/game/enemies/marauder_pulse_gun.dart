import 'package:flame/components.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/game/enemies/enemy.dart';
import 'package:stardash/game/enemies/marauder_shot.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/util/component_recycler.dart';
import 'package:stardash/util/random.dart';

class MarauderPulseGun extends Component with HasContext {
  MarauderPulseGun(this.source);

  final Enemy source;

  double _cool_down = rng.nextDouble();

  int _fire_salvo = 5;

  final _projectiles = ComponentRecycler(() => MarauderShot());

  @override
  void update(double dt) {
    if (source.state == EnemyState.exploding) removeFromParent();
    if (source.state == EnemyState.defeated) removeFromParent();
    if (source.state == EnemyState.left) removeFromParent();
    if (source.state != EnemyState.active) return;

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

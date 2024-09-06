import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/game_messages.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:voxone/game/soundboard.dart';
import 'package:voxone/util/messaging.dart';
import 'package:flame/components.dart';

class Imprisoned extends Component {
  bool _on_fire = false;

  @override
  void onMount() {
    super.onMount();
    my_prop.when_hit.add(() {
      if (my_prop.flammable?.on_fire == true) {
        if (_on_fire) return;
        _on_fire = true;
        soundboard.play(Sound.prisoner_oh_oh);
        return;
      }
      soundboard.play(Sound.prisoner_ouch);
    });
    my_prop.when_destroyed.add(() => soundboard.play(Sound.prisoner_death));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (my_prop.isRemoved || my_prop.isRemoving || !my_prop.isMounted) return;

    final close = player.position.distanceToSquared(my_prop.position) < 180;
    if (!close) return;

    my_prop.removeFromParent();

    soundboard.play(Sound.prisoner_freed);

    sendMessage(PrisonerFreed(my_prop));
  }
}

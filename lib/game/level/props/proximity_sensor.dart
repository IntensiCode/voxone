import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../../game_context.dart';

class ProximitySensor extends Component {
  ProximitySensor({
    required this.center,
    required this.radius,
    required this.when_triggered,
    this.single_shot = true,
  });

  final Vector2 center;
  final double radius;
  final Function when_triggered;
  final bool single_shot;

  @override
  void update(double dt) {
    super.update(dt);
    if (isRemoved || isRemoving) return;

    if (player.center.distanceToSquared(center) < radius * radius) {
      logInfo('proximity triggered');
      when_triggered();
      if (single_shot) {
        logInfo('proximity removed');
        removeFromParent();
      }
    }
  }
}

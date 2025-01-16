import 'package:flame/components.dart';
import 'package:voxone/game/shared/stacked_entity.dart';

mixin FakeThreeDee on PositionComponent {
  StackedEntity? linked_entity;
  double? fake_height;
  double? base_scale;
  double? descale;

  @override
  void update(double dt) {
    super.update(dt);

    linked_entity?.fake_height = fake_height;

    priority = position.y.toInt() + (fake_height ?? 0).toInt();

    if (base_scale != null) {
      final d = scale.x - base_scale!;
      priority += (d * (descale ?? 1000)).toInt();
    }
  }
}

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/stacked_entity.dart';

mixin FakeThreeDee on PositionComponent {
  StackedEntity? linked_entity;
  double? base_scale;
  double? descale;

  double? _fake_height;

  double get fake_height {
    if (_fake_height == null) TODO('fake height init missing for $this');
    return _fake_height ?? 0;
  }

  set fake_height(double value) {
    _fake_height = value;
    linked_entity?.fake_height = value;
  }

  // TODO late double fake_size;

  void init_fake_3d(FakeThreeDee origin) {
    fake_height = origin.fake_height;
    position.setFrom(origin.position);
  }

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

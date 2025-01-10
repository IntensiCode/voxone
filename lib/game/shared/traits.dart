import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/extra_id.dart';
import 'package:voxone/game/shared/has_context.dart';
import 'package:voxone/input/game_keys.dart';

class Friendly {}

class Hostile {}

abstract interface class Integrity {
  double get integrity_in_percent;
}

abstract interface class Player {
  NotifyingVector2 get position;

  double get integrity;

  void on_collect_extra(ExtraId which);
}

mixin PrimaryWeapon on Component {
  String get display_name;

  Sprite get icon;
}

mixin SecondaryWeapon on HasContext {
  var button = GameKey.b_button;

  String get display_name;

  Sprite get icon;

  double cooldown = 0;
  double cooldown_time = 3;

  late Function(SecondaryWeapon) on_fired;

  @override
  void update(double dt) {
    if (cooldown > 0) return;
    if (keys.held[button] != true) return;
    do_fire();
    on_fired(this);
  }

  void do_fire();
}

abstract class Target {
  bool get susceptible;

  void on_hit({Set<Vector2>? intersections, double damage = 1});
}

extension HasContextExtensions on HasContext {
  Player get player => cache['player'];
}

extension ShapeHitboxExtensions on ShapeHitbox {
  bool isFriendly() => parent is Friendly || parent is HasTraits && (parent as HasTraits).hasTrait<Friendly>();
}

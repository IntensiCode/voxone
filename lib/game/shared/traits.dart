import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:voxone/core/traits.dart';
import 'package:voxone/game/shared/has_context.dart';

class Friendly {}

class Hostile {}

abstract interface class Integrity {
  double get integrity_in_percent;
}

abstract interface class Player {
  NotifyingVector2 get position;

  double get integrity;
}

abstract interface class Target {
  bool get susceptible;

  void on_hit([double damage = 1]);
}

extension HasContextExtensions on HasContext {
  Player get player => cache['player'];
}

extension ShapeHitboxExtensions on ShapeHitbox {
  bool isFriendly() => parent is Friendly || parent is HasTraits && (parent as HasTraits).hasTrait<Friendly>();
}

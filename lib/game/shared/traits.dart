import 'package:flame/game.dart';

class Friendly {}

class Hostile {}

abstract interface class Player {
  NotifyingVector2 get position;

  double get integrity;
}

abstract interface class Target {
  bool get susceptible;

  void on_hit([double damage = 1]);
}

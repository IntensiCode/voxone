import 'package:flame/game.dart';

mixin Marauder {
  MarauderState get state;

  NotifyingVector2 get position;
}

enum MarauderState {
  incoming,
  active,
  sweeping,
  leaving,
  left,
  exploding,
  defeated,
}

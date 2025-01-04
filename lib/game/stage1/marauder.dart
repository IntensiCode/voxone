import 'package:flame/game.dart';

mixin Marauder {
  bool get defeated => state == MarauderState.defeated || state == MarauderState.left;

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

import 'package:flame/game.dart';
import 'package:voxone/game/shared/traits.dart';

mixin Marauder implements Hostile, Target {
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

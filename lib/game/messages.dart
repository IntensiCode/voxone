import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_phase.dart';

class GamePhaseUpdate with Message {
  GamePhaseUpdate(this.phase);

  final GamePhase phase;
}

class PlayerReady with Message {}

import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_phase.dart';

class EnemiesDefeated with Message {}

class GamePhaseUpdate with Message {
  GamePhaseUpdate(this.phase);

  final GamePhase phase;
}

class PlayerReady with Message {}

class ShowInfoText with Message {
  ShowInfoText({this.title, required this.text, this.blink_text = true, this.when_done});

  final String? title;
  final String text;
  final bool blink_text;
  final Function? when_done;
}

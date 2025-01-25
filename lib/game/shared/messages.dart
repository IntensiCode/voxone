import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/game_phase.dart';

class EnemiesDefeated with Message {}

class GamePhaseUpdate with Message {
  GamePhaseUpdate(this.phase);

  final GamePhase phase;
}

class PlayerDestroyed with Message {}

class PlayerReady with Message {}

class Rumble with Message {
  Rumble({this.duration = 1});

  final double duration;
}

class ShowInfoText with Message {
  ShowInfoText({
    this.title,
    required this.text,
    this.blink_text = true,
    this.hud_align = false,
    this.stay_longer = false,
    this.when_done,
  });

  String? title;
  final String text;
  final bool blink_text;
  final bool hud_align;
  final bool stay_longer;
  final Function? when_done;
}

class ToggleCheatMode with Message {}

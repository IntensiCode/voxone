import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_phase.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:flame_tiled/flame_tiled.dart';

class EnterRound with Message {}

class ExtraLife with Message {}

class GameComplete with Message {}

class GameOver with Message {}

class LevelComplete with Message {}

class LevelReady with Message {}

class LoadLevel with Message {}

class PlayerDied with Message {}

class PlayerDying with Message {}

class PlayerReady with Message {}

class Collected with Message {
  Collected(this.consumable);

  final LevelProp consumable;
}

class GamePhaseUpdate with Message {
  GamePhaseUpdate(this.phase);

  final GamePhase phase;
}

class LevelDataAvailable with Message {
  LevelDataAvailable(this.map);

  final TiledMap map;
}

class PrisonerFreed with Message {
  PrisonerFreed(this.prop);

  final LevelProp prop;
}

class WeaponBonus with Message {
  WeaponBonus(this.type);

  WeaponType type;
}

class WeaponEmpty with Message {
  WeaponEmpty(this.type);

  WeaponType type;
}

class WeaponSwitched with Message {
  WeaponSwitched(this.type);

  WeaponType type;
}

import 'dart:async';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/decals.dart';
import 'package:voxone/game/entities/prisoners.dart';
import 'package:voxone/game/explosions.dart';
import 'package:voxone/game/game_entities.dart';
import 'package:voxone/game/hud.dart';
import 'package:voxone/game/level/path_finder.dart';
import 'package:voxone/game/particles.dart';
import 'package:voxone/game/player/grenades.dart';
import 'package:voxone/game/player/weapons.dart';
import 'package:voxone/game/weapons_hud.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/functions.dart';
import 'package:voxone/util/game_script_functions.dart';
import 'package:voxone/util/keys.dart';
import 'package:voxone/util/messaging.dart';
import 'package:voxone/util/shortcuts.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import 'game_context.dart';
import 'game_messages.dart';
import 'game_phase.dart';
import 'game_state.dart';
import 'level/level.dart';
import 'player/player.dart';

class GameModel extends Component with AutoDispose, GameScriptFunctions, HasAutoDisposeShortcuts, HasVisibility {
  GameModel({required this.keys}) {
    model = this;
  }

  final Keys keys;

  final state = GameState.instance;

  late final GameEntities entities;
  late final Level level;
  late final Prisoners prisoners;
  late final Player player;
  late final Weapons weapons;
  late final Grenades grenades;
  late final Particles particles;
  late final Explosions explosions;
  late final Decals decals;
  late final PathFinder path_finder;

  GamePhase _phase = GamePhase.game_over;

  GamePhase get phase => _phase;

  set phase(GamePhase value) {
    if (_phase == value) return;
    _phase = value;
    sendMessage(GamePhaseUpdate(_phase));
  }

  @override
  bool get is_active => phase == GamePhase.game_on;

  // Component

  bool closed = false;

  @override
  FutureOr<void> add(Component component) {
    if (closed) throw 'no no: $component';
    return super.add(component);
  }

  @override
  onLoad() async {
    final atlas = await image('tileset.png');
    final sprites16 = sheetWH(atlas, 16, 16);
    final sprites1632 = sheetWH(atlas, 16, 32);
    final sprites32 = sheetWH(atlas, 32, 32);

    await add(state);
    // await add(entities = GameEntities());
    // await add(level = Level(atlas, sprites16));
    // await add(prisoners = Prisoners(sprites1632));
    // await add(weapons = Weapons(sprites16));
    // await add(grenades = Grenades.make(sprites16));
    // await add(particles = Particles(sprites16));
    // await add(explosions = Explosions(sprites32));
    // await add(decals = Decals(sprites32));
    // await add(path_finder = PathFinder());

    // await entities.add(player = Player(sprites1632));

    // final weapons_hud = WeaponsHud(sprites32);
    // await hud.add(weapons_hud);
    // removed.then((_) => weapons_hud.removeFromParent());

    // onMessage<PlayerReady>((it) {});
    // onMessage<ExtraLife>((_) {
    //   state.lives++;
    //   // soundboard.play(Sound.extra_life_jingle);
    // });

    if (dev) _dev_keys();

    closed = true;
  }

  void _dev_keys() {
    logInfo('DEV KEYS');
    // onKey('x', () => sendMessage(WeaponBonus(WeaponType.assault_rifle)));
    // onKey('<A-2>', () => sendMessage(WeaponBonus(WeaponType.bazooka)));
    // onKey('<A-3>', () => sendMessage(WeaponBonus(WeaponType.flame_thrower)));
    // onKey('<A-4>', () => sendMessage(WeaponBonus(WeaponType.machine_gun)));
    // onKey('<A-5>', () => sendMessage(WeaponBonus(WeaponType.smg)));
    // onKey('<A-6>', () => sendMessage(WeaponBonus(WeaponType.shotgun)));

    //   onKey('7', () => sendMessage(SpawnExtra(ExtraId.extra_life)));
    //   onKey('b', () => add(Ball()));
    //   onKey('d', () => state.lives = 1);
    //   onKey('g', () => sendMessage(GameComplete()));
    //   onKey('l', () => sendMessage(LevelComplete()));
    //   onKey('p', () => state.blasts++);
    //   onKey('s', () => state.hack_hiscore());
    //   onKey('x', () => phase = GamePhase.game_over);
    //
    //   onKey('e', () {
    //     state.level_number_starting_at_1 = 33;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('h', () {
    //     state.hack_hiscore();
    //     phase = GamePhase.game_over_hiscore;
    //   });
    //   onKey('j', () {
    //     state.level_number_starting_at_1++;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('k', () {
    //     state.level_number_starting_at_1--;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('r', () {
    //     removeAll(children.whereType<Ball>());
    //     add(Ball());
    //   });
    //
    //   onKey('J', () {
    //     state.level_number_starting_at_1 += 5;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('K', () {
    //     state.level_number_starting_at_1 -= 5;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //
    //   onKey('<A-j>', () {
    //     state.level_number_starting_at_1 += 10;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
    //   onKey('<A-k>', () {
    //     state.level_number_starting_at_1 -= 10;
    //     state.save_checkpoint();
    //     phase = GamePhase.enter_round;
    //   });
  }

  @override
  void updateTree(double dt) {
    if (!isVisible) return;
    if (phase == GamePhase.confirm_exit) return;
    if (phase == GamePhase.game_paused) return;
    if (phase == GamePhase.game_over) return;
    if (phase == GamePhase.game_over_hiscore) return;
    super.updateTree(dt);
  }
}

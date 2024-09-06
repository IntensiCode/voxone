import 'dart:ui';

import 'package:flame/components.dart';

import '../core/common.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import '../util/functions.dart';
import '../util/game_script.dart';
import '../util/game_script_functions.dart';
import '../util/nine_patch_image.dart';
import 'game_context.dart';
import 'soundboard.dart';

class LevelBonus extends PositionComponent with AutoDispose, GameScriptFunctions, GameContext, GameScript, HasPaint {
  LevelBonus(this.when_done, {this.game_complete = false});

  final Function when_done;
  final bool game_complete;

  late final BonusContent content;

  @override
  onLoad() async {
    super.onLoad();

    position.setValues(16 + 20, 72);
    size.setValues(160, game_complete ? 96 : 64);

    final bg = await image('button_plain.png');
    fontSelect(tiny_font, scale: 1);
    add(RectangleComponent(position: -position, size: game_size, paint: pixel_paint()..color = shadow));
    add(NinePatchComponent(image: bg, size: size));
    textXY(game_complete ? 'GAME COMPLETION BONUS' : 'LEVEL BONUS', size.x / 2, 8, anchor: Anchor.topCenter);
    add(content = BonusContent(size));

    for (final it in children) {
      if (it is RectangleComponent) continue;
      it.fadeInDeep();
    }

    soundboard.play_one_shot_sample('sound/level_complete.ogg');

    if (game_complete) {
      at(1.0, () => content.lines.add(''));
      at(0.0, () => content.lines.add('DOH DEFEATED:'));
      at(1.0, () => content.lines.add('*10000 POINTS*'));
      at(0.0, () => game_state.score += 10000);

      game_state.game_complete = true;

      // if (game_state.blasts > 0) {
      //   at(1.0, () => content.lines.add(''));
      //   at(0.0, () => content.lines.add('SAVED PLASMA:'));
      //
      //   final count = game_state.blasts;
      //   for (int i = 0; i < count; i++) {
      //     final extra = (i + 1) * configuration.eog_blast_bonus;
      //     at(0.1, () {
      //       if (content.lines.last.startsWith('*')) {
      //         content.lines.removeLast();
      //       }
      //       content.lines.add('*$extra POINTS*');
      //       game_state.score += configuration.eog_blast_bonus;
      //       game_state.blasts--;
      //     });
      //   }
      // }

      // if (game_state.lives > 0) {
      //   at(1.0, () => content.lines.add(''));
      //   at(0.0, () => content.lines.add('REMAINING LIVES:'));
      //   final count = game_state.lives;
      //   for (int i = 0; i < count; i++) {
      //     final extra = (i + 1) * configuration.eog_life_bonus;
      //     at(0.1, () {
      //       if (content.lines.last.startsWith('*')) {
      //         content.lines.removeLast();
      //       }
      //       content.lines.add('*$extra POINTS*');
      //       game_state.score += configuration.eog_life_bonus;
      //       game_state.lives--;
      //     });
      //   }
      // }

      at(1.0, () => when_done());
    } else {
      // time_bonus = level.level_time.round();
    }
  }

  bool done = false;
  double and_done = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (done) return;
    if (!game_complete) _level_complete(dt);
  }

  double doh = 0;
  double counted_blasts = 0;
  double and_game_complete = 0;

  double wait = -1;
  int time_bonus = 0;
  double counted_seconds = 0;
  double all_enemies = -1;
  double level_complete = -1;

  // TODO remake into script, too
  void _level_complete(double dt) {
    if (wait < 0) {
      wait += dt;
      return;
    }

    final seconds = time_bonus;
    if (seconds > 0) {
      if (counted_seconds < seconds) {
        final was = counted_seconds.round();
        counted_seconds += dt * 50;
        final now = counted_seconds.round();
        game_state.score += (now - was) * 33;
        content.lines.clear();
        content.lines.add('TIME BONUS: $now');
        // level.level_time = (time_bonus - now).toDouble();
        return;
      }
    }

    // if (model.enemies.all_enemies_destroyed) {
    //   if (all_enemies < 0) {
    //     all_enemies += dt;
    //     if (all_enemies >= 0) {
    //       content.lines.add('ALL ENEMIES DESTROYED:');
    //     }
    //     return;
    //   }
    //   // if (all_enemies == 0) {
    //   //   content.lines.add('ALL ENEMIES DESTROYED:');
    //   // }
    //   if (all_enemies < 1) {
    //     all_enemies += dt;
    //     if (all_enemies >= 1) {
    //       content.lines.add('*EXTRA PLASMA BLAST*');
    //       game_state.blasts++;
    //       soundboard.play_one_shot_sample('sound/extra_blast.ogg');
    //     }
    //     return;
    //   }
    // }

    if (level_complete < 0) {
      level_complete += dt;
      if (level_complete >= 0) {
        content.lines.add('LEVEL COMPLETED:');
      }
      return;
    }
    // if (level_complete == 0) {
    //   content.lines.add('LEVEL COMPLETED:');
    // }
    if (level_complete < 1) {
      level_complete += dt;
      if (level_complete >= 1) {
        content.lines.add('*EXTRA PLASMA BLAST*');
        game_state.blasts++;
        soundboard.play_one_shot_sample('sound/extra_blast.ogg');
      }
      return;
    }

    if (and_done < 2) {
      and_done += dt;
      if (and_done >= 2) {
        when_done();
        done = true;
      }
    }
  }
}

class BonusContent extends Component {
  BonusContent(this.size);

  final Vector2 size;

  final lines = <String>[];

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    var y = 20.0;
    for (final it in lines) {
      tiny_font.drawStringAligned(canvas, size.x / 2, y, it, Anchor.center);
      y += 8;
    }
  }
}

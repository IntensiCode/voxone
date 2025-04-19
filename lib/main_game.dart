import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/aural/music_score.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/hud.dart';
import 'package:stardash/input/shortcuts.dart';
import 'package:stardash/main_controller.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/util/messaging.dart';
import 'package:stardash/util/performance.dart';

class MainGame extends FlameGame<MainController>
    with HasKeyboardHandlerComponents, Messaging, Shortcuts, HasPerformanceTracker, ScrollDetector {
  //
  final _ticker = Ticker(ticks: tps);

  MainGame() : super(world: MainController()) {
    game = this;
    images = this.images;
    if (kIsWeb) logAnsi = false;
    pauseWhenBackgrounded = true;
  }

  @override
  onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera = CameraComponent.withFixedResolution(
      width: game_width,
      height: game_height,
      hudComponents: [if (!kReleaseMode) _ticks(), if (!kReleaseMode) _frames()],
    );
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.viewport.add(hud);
  }

  _ticks() => RenderTps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 0),
        anchor: Anchor.topLeft,
      );

  _frames() => RenderFps(
        scale: Vector2(0.25, 0.25),
        position: Vector2(0, 8),
        anchor: Anchor.topLeft,
      );

  @override
  Future onLoad() async {
    super.onLoad();

    atlas = await game.loadTextureAtlas();

    await add(audio);
    await add(music_score);
    await loadFonts(assets);
  }

  // @override
  // update(double dt) => _ticker.generateTicksFor(dt, (it) => super.update(it));

  @override
  void onScroll(PointerScrollInfo info) {
    super.onScroll(info);
    if (info.scrollDelta.global.y == 0) return;
    send(MouseWheel(info.scrollDelta.global.y.sign));
  }
}

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:stardash/aural/audio_menu.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/background/space.dart';
import 'package:stardash/core/atlas.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/screens.dart';
import 'package:stardash/input/keys.dart';
import 'package:stardash/input/shortcuts.dart';
import 'package:stardash/ui/basic_menu.dart';
import 'package:stardash/ui/flow_text.dart';
import 'package:stardash/ui/fonts.dart';
import 'package:stardash/util/auto_dispose.dart';
import 'package:stardash/util/bitmap_text.dart';
import 'package:stardash/util/extensions.dart';
import 'package:stardash/util/functions.dart';

class WebPlayScreen extends AutoDisposeComponent with HasAutoDisposeShortcuts {
  WebPlayScreen() {
    add(space);
    add(_keys);
  }

  final _keys = Keys();

  @override
  void onMount() => onKey('<Space>', () => _leave());

  @override
  void update(double dt) {
    super.update(dt);
    if (_keys.check_and_consume(GameKey.start)) _leave();
  }

  @override
  onLoad() async {
    add(FlowText(
      text: 'Hint:\n\nIf keyboard controls are not working, press <TAB> once to focus the game.',
      background: atlas.sprite('button_plain.png'),
      font: mini_font,
      position: Vector2(64, game_center.y - 8),
      anchor: Anchor.topLeft,
      size: Vector2(200, 64),
      centered_text: true,
    ));
    if (kIsWeb) {
      add(FlowText(
        text: 'Hint:\n\nPress F11 to toggle fullscreen mode.',
        background: atlas.sprite('button_plain.png'),
        font: mini_font,
        position: Vector2(64, game_center.y + 72),
        anchor: Anchor.topLeft,
        size: Vector2(200, 64),
        centered_text: true,
      ));
    }

    add(BasicMenu<AudioMenuEntry>(
      keys: _keys,
      font: mini_font,
      onSelected: _selected,
      spacing: 10,
    )
      ..addEntry(AudioMenuEntry.master_volume, 'Start')
      ..addEntry(AudioMenuEntry.music_and_sound, 'Music & Sound')
      ..addEntry(AudioMenuEntry.music_only, 'Music Only')
      ..addEntry(AudioMenuEntry.sound_only, 'Sound Only')
      ..addEntry(AudioMenuEntry.silent_mode, 'Silent Mode')
      ..preselectEntry(AudioMenuEntry.master_volume)
      ..position.setValues(game_center.x, game_center.y - 16)
      ..anchor = Anchor.topCenter);

    final anim = animCR('splash_anim.png', 2, 7, loop: false, vertical: true);
    final logo = added(SpriteComponent(
      sprite: anim.frames.last.sprite,
      anchor: Anchor.topCenter,
      position: Vector2(game_center.x, 64),
    )..opacity = 0);
    final it = added(SpriteAnimationComponent(
      animation: anim,
      removeOnFinish: true,
      anchor: Anchor.topCenter,
      position: Vector2(game_center.x, 64),
    ));
    it.animationTicker?.completed.then((_) {
      add(BitmapText(
        text: "A",
        font: menu_font,
        anchor: Anchor.topCenter,
        position: Vector2(game_center.x, 32),
      )..fadeInDeep());
      add(BitmapText(
        text: "GAME",
        font: menu_font,
        anchor: Anchor.topCenter,
        position: Vector2(game_center.x, 160),
      )..fadeInDeep());
      logo.opacity = 1;
      add(BitmapText(
        text: "AN INTENSICODE PRESENTATION",
        anchor: Anchor.bottomCenter,
        position: Vector2(game_center.x, game_height - 16),
      )..fadeInDeep());
    });
    audio.play_one_shot_sample('psychocell.ogg', cache: false);
  }

  void _selected(AudioMenuEntry it) {
    switch (it) {
      case AudioMenuEntry.master_volume:
        _leave();
      case AudioMenuEntry.music_and_sound:
        audio.audio_mode = AudioMode.music_and_sound;
        _leave();
      case AudioMenuEntry.music_only:
        audio.audio_mode = AudioMode.music_only;
        _leave();
      case AudioMenuEntry.sound_only:
        audio.audio_mode = AudioMode.sound_only;
        _leave();
      case AudioMenuEntry.silent_mode:
        audio.audio_mode = AudioMode.silent;
        _leave();
      case _: // ignore
        _leave();
    }
  }

  void _leave() {
    fadeOutDeep();
    removed.then((_) => showScreen(Screen.title));
  }
}

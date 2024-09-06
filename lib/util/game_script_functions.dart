import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../core/common.dart';
import '../util/auto_dispose.dart';
import '../util/bitmap_button.dart';
import '../util/bitmap_font.dart';
import '../util/bitmap_text.dart';
import '../util/debug.dart';
import '../util/extensions.dart';
import '../util/fonts.dart';
import 'functions.dart';

// don't look here. at least not initially. none of this you should reuse. this
// is a mess. but the mess works for the case of this demo game. all of this
// should be replaced by what you need for your game.

mixin GameScriptFunctions on Component, AutoDispose {
  Future<BitmapButton> add_button(
    Image bg,
    String text,
    double x,
    double y,
    Anchor anchor,
    Function() onTap,
  ) async {
    final it = BitmapButton(
      bg_nine_patch: bg,
      text: text,
      font: menu_font,
      font_scale: 0.5,
      position: Vector2(x, y),
      anchor: anchor,
      onTap: (_) => onTap(),
    );
    await add(it);
    return it;
  }

  void clearByType(List types) {
    final what = types.isEmpty ? children : children.where((it) => types.contains(it.runtimeType));
    removeAll(what);
  }

  void delay(double seconds) async {
    final millis = (seconds * 1000).toInt();
    await Stream.periodic(Duration(milliseconds: millis)).first;
  }

  DebugText? debugXY(String Function() text, double x, double y, [Anchor? anchor, double? scale]) {
    if (kReleaseMode) return null;
    return added(DebugText(text: text, position: Vector2(x, y), anchor: anchor, scale: scale));
  }

  T fadeIn<T extends Component>(T it, {double duration = 0.2}) {
    it.fadeInDeep(seconds: duration);
    return it;
  }

  BitmapFont? font;
  double? fontScale;

  fontSelect(BitmapFont? font, {double? scale = 1}) {
    this.font = font;
    fontScale = scale;
  }

  Future<SpriteComponent> sprite({
    required String filename,
    Vector2? position,
    Anchor? anchor,
  }) async =>
      added(await sprite_comp(filename, position: position, anchor: anchor));

  Future<SpriteComponent> spriteSXY(Sprite sprite, double x, double y, [Anchor anchor = Anchor.center]) async {
    final it = SpriteComponent(sprite: sprite, position: Vector2(x, y), anchor: anchor);
    await add(it);
    return it;
  }

  SpriteComponent spriteIXY(Image image, double x, double y, [Anchor anchor = Anchor.center]) =>
      added(SpriteComponent(sprite: Sprite(image), position: Vector2(x, y), anchor: anchor));

  Future<SpriteComponent> spriteXY(String filename, double x, double y, [Anchor anchor = Anchor.center]) async =>
      added(await sprite_comp(filename, position: Vector2(x, y), anchor: anchor));

  void fadeInByType<T extends Component>([bool reset = false]) async {
    children.whereType<T>().forEach((it) => it.fadeInDeep(restart: reset));
  }

  void fadeOutByType<T extends Component>([bool reset = false]) async {
    children.whereType<T>().forEach((it) => it.fadeOutDeep(restart: reset));
  }

  void fadeOutAll([double duration = 0.2]) {
    for (final it in children) {
      it.fadeOutDeep(seconds: duration);
    }
  }

  Future<SpriteAnimationComponent> makeAnimCRXY(
    String filename,
    int columns,
    int rows,
    double x,
    double y, {
    Anchor anchor = Anchor.center,
    bool loop = true,
    double stepTime = 0.1,
  }) async {
    final animation = await animCR(filename, columns, rows, stepTime, loop);
    return makeAnim(animation, Vector2(x, y), anchor);
  }

  SpriteAnimationComponent makeAnimXY(SpriteAnimation animation, double x, double y, [Anchor anchor = Anchor.center]) =>
      makeAnim(animation, Vector2(x, y), anchor);

  SpriteAnimationComponent makeAnim(SpriteAnimation animation, Vector2 position, [Anchor anchor = Anchor.center]) =>
      added(SpriteAnimationComponent(
        animation: animation,
        position: position,
        anchor: anchor,
      ));

  Future<BitmapButton> menuButtonXY(
    String text,
    double x,
    double y, [
    Anchor? anchor,
    String? bgNinePatch,
    Function(BitmapButton)? onTap,
  ]) {
    return menuButton(text: text, pos: Vector2(x, y), anchor: anchor, bgNinePatch: bgNinePatch, onTap: onTap);
  }

  Future<BitmapButton> menuButton({
    required String text,
    Vector2? pos,
    Anchor? anchor,
    String? bgNinePatch,
    void Function(BitmapButton)? onTap,
  }) async {
    final button = await images.load(bgNinePatch ?? 'button_plain.png');
    final it = BitmapButton(
      bg_nine_patch: button,
      text: text,
      font: menu_font,
      font_scale: 0.25,
      position: pos,
      anchor: anchor,
      onTap: onTap ?? (_) => {},
    );
    add(it);
    return it;
  }

  void scaleTo(Component it, double scale, double duration, Curve? curve) {
    it.add(
      ScaleEffect.to(
        Vector2.all(scale.toDouble()),
        EffectController(duration: duration.toDouble(), curve: curve ?? Curves.decelerate),
      ),
    );
  }

  BitmapText textXY(String text, double x, double y, {Anchor anchor = Anchor.center, double? scale}) =>
      this.text(text: text, position: Vector2(x, y), anchor: anchor, scale: scale);

  BitmapText text({
    required String text,
    required Vector2 position,
    Anchor? anchor,
    double? scale,
  }) {
    final it = BitmapText(
      text: text,
      position: position,
      anchor: anchor ?? Anchor.center,
      font: font,
      scale: scale ?? fontScale ?? 1,
    );
    add(it);
    return it;
  }
}

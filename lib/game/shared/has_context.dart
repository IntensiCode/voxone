import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:voxone/game/shared/game_screen.dart';
import 'package:voxone/game/shared/messages.dart';
import 'package:voxone/game/shared/stage_cache.dart';
import 'package:voxone/util/keys.dart';
import 'package:voxone/util/messaging.dart';

/// Mixin to provide cross-component-hierarchy access to other, shared components. The [stage] is always required as
/// the root. The [cache] is used to lookup everything only once. Many components need shared components like for
/// example [Decals]. To not have all this references explicitly everywhere, this mixin is used instead.
mixin HasContext on Component {
  GameScreen? _stage;
  CollisionDetection<ShapeHitbox, Sweep<ShapeHitbox>>? _collision;

  GameScreen get stage => _stage ??= findParent<GameScreen>(includeSelf: true)!;

  StageCache get cache => stage.stage_cache;

  Keys get keys => stage.stage_keys;

  CollisionDetection<ShapeHitbox, Sweep<ShapeHitbox>> get collisionDetection => _collision ??= stage
      .ancestors(includeSelf: true)
      .whereType<HasCollisionDetection<Sweep<ShapeHitbox>>>()
      .first
      .collisionDetection;

  void info(String message, {String? title, bool blink = true, bool hud = false, Function? done}) =>
      sendMessage(ShowInfoText(
        title: title,
        text: message,
        blink_text: blink,
        hud_align: hud,
        when_done: done,
      ));
}

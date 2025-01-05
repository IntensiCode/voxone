import 'package:flame/components.dart';
import 'package:voxone/game/shared/game_screen.dart';
import 'package:voxone/game/shared/stage_cache.dart';
import 'package:voxone/util/keys.dart';

extension GameScreenExtensions on GameScreen {
  T first<T>() => descendants(includeSelf: true).whereType<T>().first;
}

/// Mixin to provide cross-component-hierarchy access to other, shared components. The [stage] is always required as
/// the root. The [cache] is used to lookup everything only once. Many components need shared components like for
/// example [Decals]. To not have all this references explicitly everywhere, this mixin is used instead.
mixin HasContext on Component {
  GameScreen? _stage;

  GameScreen get stage => _stage ??= findParent<GameScreen>(includeSelf: true)!;

  StageCache get cache => stage.stage_cache;

  Keys get keys => stage.stage_keys;
}

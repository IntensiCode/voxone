import 'package:flame/game.dart';
import 'package:voxone/game/shared/friendly_target.dart';
import 'package:voxone/game/shared/has_context.dart';

extension HasContextExtension on HasContext {
  PlayerTarget get player => cache.putIfAbsent('player', () {
        return stage.descendants(includeSelf: true).whereType<PlayerTarget>().first;
      }) as PlayerTarget;
}

mixin PlayerTarget on FriendlyTarget {
  NotifyingVector2 get position;
}

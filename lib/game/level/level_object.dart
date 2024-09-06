import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/level_state.dart';
import 'package:voxone/game/level/props/destructible.dart';
import 'package:voxone/game/level/props/flammable.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:voxone/game/player/weapon_type.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/random.dart';
import 'package:flame/components.dart';

mixin LevelObject on SpriteComponent, HasVisibility {
  final _hit_bounds = MutableRectangle(0.0, 0.0, 0.0, 0.0);
  final _visual_bounds = MutableRectangle(0.0, 0.0, 0.0, 0.0);
  final _walk_bounds = MutableRectangle(0.0, 0.0, 0.0, 0.0);

  late final Paint level_paint;

  late double hit_width;
  late double hit_height;
  late double visual_width;
  late double visual_height;

  Map<String, dynamic> properties = {};

  int _frame_check = rng.nextInt(10);

  final when_destroyed = <Hook>{};
  final when_hit = <Hook>{};
  final when_removed = <Hook>{};

  bool? force_visible;
  double? force_opacity;

  Rectangle<double> get hit_bounds => _hit_bounds;

  Rectangle<double> get visual_bounds => _visual_bounds;

  Rectangle<double> get walk_bounds => _walk_bounds;

  void update_bounds() {
    _hit_bounds.left = position.x - hit_width / 2;
    _hit_bounds.top = position.y - hit_height;
    _hit_bounds.width = hit_width;
    _hit_bounds.height = hit_height;

    _visual_bounds.left = position.x - visual_width / 2;
    _visual_bounds.top = position.y - visual_height;
    _visual_bounds.width = visual_width;
    _visual_bounds.height = visual_height;

    _walk_bounds.left = position.x - hit_width / 2;
    _walk_bounds.top = position.y - hit_height;
    _walk_bounds.width = hit_width;
    _walk_bounds.height = hit_height;
  }

  bool is_blocked_for_walking(Rectangle rect, {bool enemy = false}) {
    if (properties['friendly'] == true) {
      return false;
    }
    if (enemy && this.enemy != null) {
      return false;
    }
    if (properties['walk_behind'] == true) {
      // walk through unless a specific height is given (fences have small height for example):
      if (hit_height == 0 || hit_height == 16) return false;
    }
    return _walk_bounds.intersects(rect);
  }

  bool is_hit_by(Vector2 position) {
    if (hit_height == 0) return false;

    if (position.x < _hit_bounds.left) return false;
    if (position.x > _hit_bounds.right) return false;
    if (position.y < _hit_bounds.top) return false;
    if (position.y > _hit_bounds.bottom) return false;

    if (properties['walk_behind'] == true) {
      return false;
    }

    return true;
  }

  void on_hit(WeaponType type) {
    final it = children.whereType<Destructible>().singleOrNull;
    if (it == null) throw 'hit on non destructible';
    it.on_hit(type);

    final fire_damage = type.fire_damage;
    if (fire_damage != null) {
      final it = children.whereType<Flammable>().singleOrNull;
      it?.on_hit(fire_damage);
    }
  }

  @override
  bool get isVisible {
    if (force_visible != null) return force_visible!;
    final visible = game.camera.visibleWorldRect;
    return position.y < visible.bottom + height && position.y > visible.top;
  }

  @override
  void onMount() {
    super.onMount();
    update_bounds();
    removed.then((_) {
      when_removed.forEach((it) => it());
      when_removed.clear();
      when_destroyed.clear();
      when_hit.clear();
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    switch (level.state) {
      case LevelState.waiting:
        return;
      case LevelState.appearing:
        paint = level_paint;
      case LevelState.active:
        if (paint == level_paint) paint = pixel_paint();
        _update(dt);
      case LevelState.defeated:
        return;
    }
  }

  void _update(double dt) {
    if (force_opacity != null) {
      opacity = force_opacity!;
      return;
    }

    if (++_frame_check < 6) return;
    _frame_check = 0;

    final player_close = _visual_bounds.intersects(player.bounds);
    final player_behind = player.position.y <= priority;
    opacity = min(level_paint.opacity, player_close && player_behind ? 0.5 : 1.0);
  }
}

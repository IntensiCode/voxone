import 'dart:ui';

import 'package:voxone/core/common.dart';
import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/level_object.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/tiled_extensions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';

class LevelTiles extends Component with GameContext, HasVisibility {
  LevelTiles(this._atlas, this._sprites, this._paint);

  final Image _atlas;
  final SpriteSheet _sprites;
  final Paint _paint;

  final _cached_tiles = <List<List<Gid>>>[];
  final _cached_priority = <int, int>{};
  final _cached_rect = <int, Rect>{};
  final _cached_transforms = <int, RSTransform>{};
  final _render_pos = Vector2.zero();

  late final SpriteBatch _batch;

  late TiledMap? _map;

  void reset() => _map = null;

  Future load(TiledMap map) async {
    _map = map;
    _cached_tiles.clear();

    final which = map.layers.whereType<TileLayer>();
    for (final it in which) {
      if (it.name == 'advice') continue;
      final tiles = it.tileData;
      if (tiles != null) _cached_tiles.add(tiles);
    }

    final tileset = _map!.tilesetByName('tileset');

    for (var y = 0; y < map.height; y++) {
      final row_index = _map!.height - y - 1;
      if (row_index < 0) continue;

      final map_width = _map!.width;
      for (var x = 0; x < map_width; x++) {
        _render_pos.setValues(x * 16, (16 - y - 1) * 16);

        for (var t = 0; t < _cached_tiles.length; t++) {
          if (t == 0) continue;

          final tiles = _cached_tiles[t];
          final row = tiles[row_index];
          final gid = row[x];
          if (gid.tile == 0) continue;

          final index = (gid.tile - tileset.firstGid!).clamp(0, tileset.tileCount! - 1);
          final priority = _cached_priority[gid.tile] ??= tileset.priority(gid.tile - 1);

          final merged_properties = <String, dynamic>{};
          final tile = tileset.tiles[index];
          for (final it in tile.properties.byName.entries) {
            merged_properties[it.key] = it.value.value;
          }
          if (tile.type != null) {
            merged_properties['type'] = tile.type!;
          }

          final it = StackedTile(
            sprite: _sprites.getSpriteById(index),
            paint: _paint,
            position: _render_pos,
            priority: _render_pos.y.toInt() + t * 16 - 16 + priority,
          );
          await entities.add(it);

          it.properties = merged_properties;

          it.hit_width = merged_properties['width']?.toDouble() ?? it.width;
          it.hit_height = merged_properties['height']?.toDouble() ?? it.height;
          it.visual_width = merged_properties['visual_width']?.toDouble() ?? it.hit_width;
          it.visual_height = merged_properties['visual_height']?.toDouble() ?? it.hit_width;
        }
      }
    }
  }

  @override
  bool get isVisible => _map != null;

  @override
  Future onLoad() async {
    super.onLoad();
    _batch = SpriteBatch(_atlas, useAtlas: !kIsWeb);
  }

  @override
  void render(Canvas canvas) {
    if (_map == null) return;
    super.render(canvas);

    final stacking = List.generate(_cached_tiles.length, (_) => _Stacking());

    final tileset = _map!.tilesetByName('tileset');

    final int off = (game.camera.visibleWorldRect.top / 16).abs().toInt();
    for (var y = off + 15; y >= off; y--) {
      final row_index = _map!.height - y - 1;
      if (row_index < 0) continue;

      final map_width = _map!.width;
      for (var x = 0; x < map_width; x++) {
        for (var t = 0; t < _cached_tiles.length; t++) {
          final tiles = _cached_tiles[t];
          final row = tiles[row_index];
          final gid = row[x];
          if (gid.tile == 0) continue;

          final s = stacking[t];
          s.priority = _cached_priority[gid.tile] ??= tileset.priority(gid.tile - 1);
          if (s.priority > 0) continue;

          s.rect = _cached_rect[gid.tile] ??= tileset.rect(gid.tile - 1);
        }

        stacking.sort((a, b) => a.priority - b.priority);

        _render_pos.setValues(x * 16, (15 - y - 1) * 16);
        for (final it in stacking) {
          if (it.rect != null) {
            final trans = _cached_transforms[x + y * map_width] ??= _render_pos.transform;
            _batch.addTransform(source: it.rect!, transform: trans);
          }
          it.priority = 0;
          it.rect = null;
        }
      }
    }
    _batch.render(canvas, paint: _paint);
    _batch.clear();
  }
}

class _Stacking {
  int priority = 0;
  Rect? rect;
}

class StackedTile extends SpriteComponent with HasVisibility, LevelObject {
  StackedTile({
    required super.sprite,
    required Paint paint,
    required super.position,
    required super.priority,
  }) : super(anchor: Anchor.bottomCenter) {
    level_paint = paint;
    position.x += width / 2;

    hit_width = 16;
    hit_height = 16;
    visual_width = 16;
    visual_height = 16;
  }

  @override
  String toString() => '$properties with $children at $position';
}

import 'dart:ui';

import 'package:voxone/game/entities/enemy.dart';
import 'package:voxone/game/entities/finds_cover.dart';
import 'package:voxone/game/entities/movement_closes_in.dart';
import 'package:voxone/game/entities/movement_runs_across.dart';
import 'package:voxone/game/entities/movement_stationary.dart';
import 'package:voxone/game/entities/property_behavior.dart';
import 'package:voxone/game/entities/spawn_late.dart';
import 'package:voxone/game/entities/spawn_stacked.dart';
import 'package:voxone/game/entities/throws_grenade.dart';
import 'package:voxone/game/game_context.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/functions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flame_tiled/flame_tiled.dart';

import 'props/consumable.dart';
import 'props/crack_when_hit.dart';
import 'props/destructible.dart';
import 'props/explode_on_contact.dart';
import 'props/explosive.dart';
import 'props/flammable.dart';
import 'props/imprisoned.dart';
import 'props/level_prop.dart';
import 'props/level_prop_extensions.dart';
import 'props/smoke_when_hit.dart';
import 'props/spawn_score.dart';
import 'props/spawn_when_close.dart';
import 'props/spawned.dart';

class LevelProps extends Component with GameContext, HasVisibility {
  LevelProps(this._atlas, this._name, this._width, this._height, this._paint);

  final Image _atlas;
  final String _name;
  final int _width;
  final int _height;
  final Paint _paint;

  late final SpriteSheet _sprites;

  String? tileset_override;

  TiledMap? _map;

  void reset() {
    _map = null;
    model.removeAll(model.children.whereType<LevelProp>());
  }

  Future load(TiledMap map) async {
    _map = map;

    final tileset = _map!.tilesetByName(tileset_override ?? '${_name}_atlas');
    final props = _map!.layerByName('${_name}_atlas') as ObjectGroup;
    final pos = Vector2.zero();
    for (final it in props.objects) {
      final priority = it.properties.byName['priority'] as IntProperty?;

      final index = (it.gid! - tileset.firstGid!).clamp(0, tileset.tileCount! - 1);

      final tile = tileset.tiles[index];

      final merged_properties = <String, dynamic>{};
      for (final it in it.properties.byName.entries) {
        merged_properties[it.key] = it.value.value;
      }
      for (final it in tile.properties.byName.entries) {
        merged_properties[it.key] ??= it.value.value;
      }
      if (tile.type != null) {
        merged_properties['type'] = tile.type!;
      }

      pos.setValues(it.x, (15 - _map!.height) * 16 + it.y);

      final actual_priority = pos.y.toInt() + (priority?.value ?? 0);
      final behaviors = _behaviors_from(merged_properties);
      final prop = LevelProp(
        sprite: _sprites.getSpriteById(index),
        paint: _paint,
        position: pos,
        priority: actual_priority,
        children: behaviors,
      );
      prop.properties = merged_properties;

      final consumable = prop.is_consumable;
      if (consumable) prop.priority = (pos.y - 15).toInt();

      prop.hit_width = merged_properties['width']?.toDouble() ?? prop.width;
      prop.hit_height = merged_properties['height']?.toDouble() ?? prop.height;
      prop.visual_width = merged_properties['visual_width']?.toDouble() ?? prop.hit_width;
      prop.visual_height = merged_properties['visual_height']?.toDouble() ?? prop.hit_width;

      _call_post_mount(prop);

      await entities.add(prop);
    }
  }

  Set<Component> _behaviors_from(Map<String, dynamic> properties) {
    final result = <Component>{};

    var destructible = false;
    if (properties['destructible'] == true) destructible = true;
    if (properties['grenade_hits'] != null) destructible = true;
    if (properties['hits'] != null) destructible = true;
    if (destructible) result.add(Destructible());

    if (properties['closes_in'] == true) result.add(MovementClosesIn());
    if (properties['consumable'] == true) result.add(Consumable());
    if (properties['crack_when_hit'] == true) result.add(CrackWhenHit(_sprites.getSpriteById(414)));
    if (properties['enemy'] == true) result.add(Enemy(_sprites));
    if (properties['explode_on_contact'] == true) result.add(ExplodeOnContact());
    if (properties['explosive'] == true) result.add(Explosive());
    if (properties['finds_cover'] == true) result.add(FindsCover());
    if (properties['flammable'] == true) result.add(Flammable());
    if (properties['imprisoned'] == true) result.add(Imprisoned());
    if (properties['runs_across'] == true) result.add(MovementRunsAcross());
    if (properties['smoke_when_hit'] == true) result.add(SmokeWhenHit());
    if (properties['spawn_late'] == true) result.add(SpawnLate());
    if (properties['spawn_score'] == true) result.add(SpawnScore());
    if (properties['spawn_stacked'] == true) result.add(SpawnStacked());
    if (properties['spawn_when_close'] == true) result.add(SpawnWhenClose());
    if (properties['spawned'] == true) result.add(Spawned());
    if (properties['stationary'] == true) result.add(MovementStationary());
    if (properties['throws_grenade'] == true) result.add(ThrowsGrenade());

    return result;
  }

  void _call_post_mount(LevelProp prop) {
    final done = <PropertyBehavior>[];
    while (true) {
      final now = [...prop.children.whereType<PropertyBehavior>()];
      now.removeAll(done);
      if (now.isEmpty) break;
      for (final it in now) {
        it.post_mount();
      }
      done.addAll(now);
    }
  }

  @override
  bool get isVisible => _map != null;

  @override
  Future onLoad() async {
    super.onLoad();
    _sprites = sheetWH(_atlas, _width, _height);
  }

  @override
  void renderTree(Canvas canvas) {
    if (_map == null) return;
    super.renderTree(canvas);
  }
}

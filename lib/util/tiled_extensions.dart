import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_tiled/flame_tiled.dart';

extension ObjectGroupExtensions on ObjectGroup {
  TiledObject objectByName(String name) => objects.firstWhere((it) => it.name == name);
}

extension RenderableTiledMapExtensions on RenderableTiledMap {
  TileLayer requireTileLayer(String name) {
    final it = getLayer(name);
    if (it == null) throw ArgumentError('Required layer $name not found');
    return it as TileLayer;
  }

  void refresh(Layer layer) {
    final it = renderableLayers.firstWhere((it) => it.layer.id == layer.id);
    it.refreshCache();
  }

  void renderSingleLayer(Canvas canvas, String name) {
    final it = renderableLayers.firstWhere((it) => it.layer.name == name);
    it.render(canvas, camera);
  }

  void setLayerHidden(Layer layer) {
    final index = renderableLayers.indexWhere((it) => it.layer.id == layer.id);
    setLayerVisibility(index, visible: false);
  }

  int? intOptProp(String name) => map.intOptProp(name);

  int intProperty(String name) => map.intProperty(name);

  String? stringOptProp(String name) => map.stringOptProp(name);

  String stringProperty(String name) => map.stringProperty(name);
}

extension TiledComponentExtensions on TiledComponent {
  T? getLayer<T extends Layer>(String name) => tileMap.getLayer<T>(name);

  void setLayerHidden(String name) {
    final it = tileMap.getLayer(name);
    if (it != null) tileMap.setLayerHidden(it);
  }

  int? intOptProp(String name) => tileMap.intOptProp(name);

  int intProperty(String name) => tileMap.intProperty(name);

  String? stringOptProp(String name) => tileMap.stringOptProp(name);

  String stringProperty(String name) => tileMap.stringProperty(name);

  int tile_priority(String tileset, int index) {
    final tiles = tileMap.map.tilesetByName(tileset);
    final tile = tiles.tiles[index];
    return (tile.properties['priority'] as IntProperty?)?.value ?? 0;
  }

  Rectangle<num> drawRect(String tileset, int index) {
    final tiles = tileMap.map.tilesetByName(tileset);
    final tile = tiles.tiles[index];
    return tiles.computeDrawRect(tile);
  }

  Sprite tileSprite(int index) {
    final image = atlases().first.$2;
    final tiles = tileMap.map.tilesetByName('tiles');
    final tile = tiles.tiles[index];
    final rect = tiles.computeDrawRect(tile);
    final pos = Vector2(rect.left.toDouble(), rect.top.toDouble());
    final size = Vector2(rect.width.toDouble(), rect.height.toDouble());
    return Sprite(image, srcPosition: pos, srcSize: size);
  }
}

extension TiledMapExtensions on TiledMap {
  int? intOptProp(String name) {
    for (final it in properties) {
      if (it.name == name && it.type == PropertyType.int) {
        return it.value as int;
      }
    }
    return null;
  }

  int intProperty(String name) => properties.firstWhere((it) => it.name == name).value as int;

  String? stringOptProp(String name) => properties.firstWhereOrNull((it) => it.name == name)?.value.toString();

  String stringProperty(String name) => properties.firstWhere((it) => it.name == name).value.toString();
}

extension TiledObjectExtensions on TiledObject {
  int get priority => properties.firstWhere((it) => it.name == 'priority').value as int;

  double? get spawnAt => properties.firstWhereOrNull((it) => it.name == 'SpawnAt')?.value as double?;

  String get spawnSpec => properties.firstWhere((it) => it.name == 'SpawnSpec').value.toString();
}

extension TilesetExtensions on Tileset {
  int priority(int index) => (tiles[index].properties['priority'] as IntProperty?)?.value ?? 0;

  Rect rect(int index) => computeDrawRect(tiles[index]).toRect();
}

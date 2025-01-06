import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_texturepacker/flame_texturepacker.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/auto_dispose.dart';
import 'package:voxone/util/functions.dart' as f;

late Atlas atlas;

abstract interface class Atlas implements Disposable {
  Sprite sprite(String name);

  SpriteComponent spriteXY(String name, double x, double y, Anchor anchor);

  SpriteSheet sheetIWH(String name, int width, int height, {double spacing = 0, double margin = 0});

  SpriteSheet sheetI(String name, int columns, int rows);
}

class PreloadedTextureAtlas implements Atlas {
  static final _required = [
    'entities/camo_stellar_jet.png',
    'entities/dual_striker.png',
    'entities/star_runner.png',
    'entities/transstellar.png',
  ];

  final _images = <String, Image>{};

  Future preloaded() async {
    for (final it in _required) {
      await preload(it);
      logInfo('preloaded: $it');
    }
  }

  Future preload(String name) async {
    final image = await images.load(name);
    _images[name] = image;
  }

  @override
  void dispose() {
    _images.values.forEach((it) => it.dispose());
    _images.clear();
  }

  @override
  Sprite sprite(String name) => Sprite(_images[name]!);

  @override
  SpriteComponent spriteXY(String name, double x, double y, Anchor anchor) =>
      SpriteComponent(sprite: sprite(name), position: Vector2(x, y), anchor: anchor);

  @override
  SpriteSheet sheetIWH(String name, int width, int height, {double spacing = 0, double margin = 0}) =>
      f.sheetWH(_images[name]!, width, height, spacing: spacing, margin: margin);

  @override
  SpriteSheet sheetI(String name, int columns, int rows) => f.sheet(_images[name]!, columns, rows);
}

class PackerTextureAtlas implements Atlas {
  PackerTextureAtlas(this._atlas);

  final TexturePackerAtlas _atlas;

  @override
  void dispose() {}

  @override
  Sprite sprite(String name) => _atlas.image(name);

  @override
  SpriteComponent spriteXY(String name, double x, double y, Anchor anchor) => _atlas.spriteXY(name, x, y, anchor);

  @override
  SpriteSheet sheetIWH(String name, int width, int height, {double spacing = 0, double margin = 0}) =>
      _atlas.sheetIWH(name, width, height, spacing: spacing, margin: margin);

  @override
  SpriteSheet sheetI(String name, int columns, int rows) => _atlas.sheetI(name, columns, rows);
}

extension FlameGameExtensions on FlameGame {
  Future<Atlas> loadTextureAtlas() async {
    try {
      return PackerTextureAtlas(await atlasFromAssets('texture.atlas'));
    } catch (it, st) {
      logError('failed loading texture atlas - ignored: $it', st);
      return PreloadedTextureAtlas()..preloaded();
    }
  }
}

extension TexturePackerAtlasExtensions on TexturePackerAtlas {
  Sprite image(String name) {
    final sprite = findSpriteByName(name.replaceFirst('.png', '').split('/').last);
    if (sprite == null) throw 'unknown atlas id: $name';
    return sprite;
  }

  SpriteComponent spriteXY(String name, double x, double y, Anchor anchor) {
    final sprite = findSpriteByName(name.replaceFirst('.png', ''));
    if (sprite == null) throw 'unknown atlas id: $name';
    return SpriteComponent(sprite: sprite, position: Vector2(x, y), anchor: anchor);
  }

  TexturePackerSpriteSheet sheetIWH(String name, int width, int height, {double spacing = 0, double margin = 0}) {
    if (margin != 0) throw 'margin not supported';
    final sprite = findSpriteByName(name.replaceFirst('.png', ''));
    if (sprite == null) throw 'unknown atlas id: $name';
    return TexturePackerSpriteSheet.wh(sprite, width, height, spacing: spacing);
  }

  TexturePackerSpriteSheet sheetI(String name, int columns, int rows) {
    final sprite = findSpriteByName(name.replaceFirst('.png', ''));
    if (sprite == null) throw 'unknown atlas id: $name';
    return TexturePackerSpriteSheet.cr(sprite, columns, rows);
  }
}

class TexturePackerSpriteSheet implements SpriteSheet {
  TexturePackerSpriteSheet.wh(this.sprite, this.tile_width, this.tile_height, {required double spacing})
      : columns = (sprite.src.width / (tile_width + spacing)).round(),
        rows = (sprite.src.height / (tile_height + spacing)).round(),
        _spacing = spacing;

  TexturePackerSpriteSheet.cr(this.sprite, this.columns, this.rows)
      : tile_width = sprite.src.width ~/ columns,
        tile_height = sprite.src.height ~/ rows,
        _spacing = 0;

  final Sprite sprite;
  final int tile_width;
  final int tile_height;
  final double _spacing;

  late final tile_size = Vector2(tile_width.toDouble(), tile_height.toDouble());

  @override
  final int columns;

  @override
  final int rows;

  @override
  Image get image => sprite.image;

  @override
  double get spacing => _spacing.toDouble();

  final _sprites = <int, Sprite>{};

  @override
  Sprite getSpriteById(int id) {
    if (!_sprites.containsKey(id)) {
      final src = sprite.src;
      final x = id % columns;
      final y = id ~/ columns;
      final xx = src.left + x * (tile_width + _spacing);
      final yy = src.top + y * (tile_height + _spacing);
      return Sprite(sprite.image, srcPosition: Vector2(xx, yy), srcSize: tile_size);
    }
    return _sprites[id]!;
  }

  @override
  Sprite getSprite(int row, int column) => getSpriteById(row * columns + column);

  @override
  SpriteAnimation createAnimation({
    required int row,
    required double stepTime,
    bool loop = true,
    int from = 0,
    int? to,
  }) {
    final end = to ?? (columns - 1);
    final sprites = [for (int i = from; i <= end; i++) getSpriteById(row * columns + i)];
    return SpriteAnimation.spriteList(sprites, stepTime: stepTime)..loop = loop;
  }

  @override
  SpriteAnimation createAnimationWithVariableStepTimes({
    required int row,
    required List<double> stepTimes,
    bool loop = true,
    int from = 0,
    int? to,
  }) {
    throw UnimplementedError();
  }

  @override
  SpriteAnimationFrameData createFrameData(int row, int column, {required double stepTime}) {
    throw UnimplementedError();
  }

  @override
  SpriteAnimationFrameData createFrameDataFromId(int spriteId, {required double stepTime}) {
    throw UnimplementedError();
  }

  @override
  double get margin => throw UnimplementedError();

  @override
  Vector2 get srcSize => throw UnimplementedError();
}

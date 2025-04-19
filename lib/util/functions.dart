import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:stardash/core/atlas.dart';

RectangleComponent rect(double x, double y, double w, double h, Paint paint) =>
    RectangleComponent(position: Vector2(x, y), size: Vector2(w, h), paint: paint);

SpriteSheet sheetWH(
  Image image,
  int frameWidth,
  int frameHeight, {
  double spacing = 0,
  double margin = 0,
}) {
  final columns = image.width ~/ frameWidth;
  final rows = image.height ~/ frameHeight;
  return SpriteSheet.fromColumnsAndRows(image: image, columns: columns, rows: rows, spacing: spacing, margin: margin);
}

SpriteSheet sheetIWH(
  String filename,
  int frameWidth,
  int frameHeight, {
  double spacing = 0,
  double margin = 0,
}) =>
    atlas.sheetIWH(filename, frameWidth, frameHeight, spacing: spacing, margin: margin);

SpriteSheet sheetI(String filename, int columns, int rows) => atlas.sheetI(filename, columns, rows);

SpriteSheet sheet(Image image, int columns, int rows) =>
    SpriteSheet.fromColumnsAndRows(image: image, columns: columns, rows: rows);

SpriteComponent sprite_comp(
  String filename, {
  Vector2? position,
  Vector2? size,
  Anchor? anchor,
}) {
  return SpriteComponent(
    sprite: atlas.sprite(filename),
    position: position,
    size: size,
    anchor: anchor,
  );
}

SpriteAnimation animCR(
  String filename,
  int columns,
  int rows, {
  double stepTime = 0.1,
  bool loop = true,
  bool vertical = false,
}) {
  final sheet = atlas.sheetI(filename, columns, rows);
  final parts = List.generate(rows, (i) => sheet.createAnimation(row: i, stepTime: stepTime, loop: loop));
  final List<SpriteAnimationFrame> frames;
  if (vertical) {
    frames = List.generate(columns, (i) => List.generate(rows, (j) => parts[j].frames[i])).flattenedToList;
  } else {
    frames = parts.map((it) => it.frames).flattenedToList;
  }
  return SpriteAnimation(frames, loop: loop);
}

SpriteAnimation animWH(
  String filename,
  int frameWidth,
  int frameHeight, [
  double stepTime = 0.1,
  bool loop = true,
]) {
  final sheet = atlas.sheetIWH(filename, frameWidth, frameHeight);
  if (sheet.rows != 1) throw ArgumentError('rows must be 1 for now');
  return sheet.createAnimation(row: 0, stepTime: stepTime, loop: loop);
}

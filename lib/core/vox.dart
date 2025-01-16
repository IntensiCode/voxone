import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/sprite.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/voxel/vox_io.dart';

Future<SpriteSheet> make_anim(int frames, Future<Image> Function(int) make_frame) async {
  final images = <Image>[];
  for (var i = 0; i < frames; i++) {
    images.add(await make_frame(i));
  }
  final width = images.map((it) => it.width + 2).sum;
  final height = images.map((it) => it.height + 2).max;
  logInfo('Creating animation with $frames frames, full size $width x $height');

  final paint = pixel_paint();
  final sheet = pixelate(width, height, (canvas) {
    var x = 0;
    for (final image in images) {
      canvas.drawImage(image, Offset(x.toDouble() + 1, 1), paint);
      x += image.width + 2;
    }
  });

  // sheet.toByteData(format: ImageByteFormat.png).then((data) {
  //   File('anim.png').writeAsBytesSync(Uint8List.view(data!.buffer));
  // });

  return SpriteSheet.fromColumnsAndRows(image: sheet, columns: frames, rows: 1, spacing: 2, margin: 1);
}

Future<Voxels> vox(String name, {bool crop = true}) {
  return game.assets.readBinaryFile('entities/$name').then((it) {
    if (it.length >= 2 && it[0] == 0x1f && it[1] == 0x8b) {
      logInfo('Decompressing $name.vox.gz');
      final data = GZipCodec().decode(it.toList());
      it = Uint8List.fromList(data);
    }
    return read_vox(it, name, crop: crop);
  });
}

Future<(Voxels, Image)> vox_image(String name, {int dx = 0, int dy = 0, int dz = 0, List<int>? blurred_argb32}) {
  return game.assets.readBinaryFile('entities/$name').then((it) {
    if (it.length >= 2 && it[0] == 0x1f && it[1] == 0x8b) {
      logInfo('Decompressing $name.vox.gz');
      final data = GZipCodec().decode(it.toList());
      it = Uint8List.fromList(data);
    }
    final voxels = read_vox(it, name);
    return (voxels, vox_to_image(voxels, dx: dx, dy: dy, dz: dz, blurred_argb32: blurred_argb32));
  });
}

Future<StackedEntity> vox_entity(
  String name,
  Shadows shadows, {
  int dx = 0,
  int dy = 0,
  int dz = 0,
  List<int>? blurred_argb32,
}) {
  return game.assets.readBinaryFile('entities/$name').then((it) async {
    final (voxels, image) = await vox_image(name, dx: dx, dy: dy, dz: dz, blurred_argb32: blurred_argb32);
    final entity = StackedEntity.sprite(Sprite(image), voxels.height, shadows);
    entity.size.x = voxels.width.toDouble();
    entity.size.y = voxels.height.toDouble();
    return entity;
  });
}

import 'dart:io';
import 'dart:typed_data';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/shared/shadows.dart';
import 'package:voxone/game/shared/stacked_entity.dart';
import 'package:voxone/voxel/vox_io.dart';

Future<StackedEntity> vox(
  String name,
  Shadows shadows, {
  int dx = 0,
  int dy = 0,
  int dz = 0,
  List<int>? blurred_argb32,
}) {
  return game.assets.readBinaryFile('entities/$name').then((it) {
    if (it.length >= 2 && it[0] == 0x1f && it[1] == 0x8b) {
      logInfo('Decompressing $name.vox.gz');
      final data = GZipCodec().decode(it.toList());
      it = Uint8List.fromList(data);
    }
    final voxels = read_vox(it, name);
    final image = vox_to_image(voxels, dx: dx, dy: dy, dz: dz, blurred_argb32: blurred_argb32);
    final entity = StackedEntity.sprite(Sprite(image), voxels.height, shadows);
    entity.size.x = voxels.width.toDouble();
    entity.size.y = voxels.height.toDouble();
    return entity;
  });
}

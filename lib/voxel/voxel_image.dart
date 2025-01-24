import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/pixelate.dart';
import 'package:voxone/voxel/voxel_io.dart';
import 'package:voxone/voxel/voxels.dart';

Image vox_to_image(
  Voxels voxels, {
  int dx = 0,
  int dy = 0,
  int dz = 0,
  List<int>? blurred_argb32,
}) {
  final blurred = blurred_argb32 ??= [];
  return pixelate(voxels.width, voxels.height * voxels.depth, (canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    final blur = MaskFilter.blur(BlurStyle.outer, 1);
    for (var y = dy; y < voxels.height + dy; y++) {
      for (var z = dz; z < voxels.depth + dz; z++) {
        for (var x = dx; x < voxels.width + dx; x++) {
          final yy = voxels.height - 1 - y + dy;
          final zz = voxels.depth - 1 - z + dz;
          final xx = voxels.width - 1 - x + dx;
          final v = voxels.voxels[yy][zz][xx];
          if (v == 0) continue;
          final color = voxels.palette[v - 1];
          paint.color = Color(color);
          if (blurred.contains(color)) {
            paint.maskFilter = blur;
            canvas.drawRect(Rect.fromLTWH(x.toDouble() - 1, y.toDouble() * voxels.depth + z - 1, 3, 3), paint);
            paint.maskFilter = null;
          }
          canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble() * voxels.depth + z, 1, 1), paint);
        }
      }
    }
  });
}

Image vox_to_image_ext(Voxels voxels, {bool Function(Vector3 xyz, int color, Canvas canvas, Paint paint)? on_pixel}) {
  return pixelate(voxels.width, voxels.height * voxels.depth, (canvas) {
    final xyz = Vector3.zero();
    final paint = pixel_paint();
    for (var y = 0; y < voxels.height; y++) {
      for (var z = 0; z < voxels.depth; z++) {
        for (var x = 0; x < voxels.width; x++) {
          final yy = voxels.height - 1 - y;
          final zz = voxels.depth - 1 - z;
          final xx = voxels.width - 1 - x;

          final v = voxels.voxels[yy][zz][xx];
          if (v == 0) continue;

          final color = voxels.palette[v - 1];
          paint.color = Color(color);

          xyz.setValues(x + 0, y + 0, z + 0);
          if (on_pixel?.call(xyz, color, canvas, paint) == true) continue;

          canvas.drawRect(Rect.fromLTWH(xyz.x, xyz.z, 1, 1), paint);
        }
      }
      canvas.translate(0, voxels.depth * 1);
    }
  });
}

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

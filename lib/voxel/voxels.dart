import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/pixelate.dart';

class Voxels {
  final int width;
  final int height;
  final int depth;
  final List<List<List<int>>> voxels; // y layers, z- then x-planes
  final List<int> palette;

  Voxels(this.width, this.height, this.depth, this.voxels, this.palette);

  Voxels remove_empty_ys_at_start_and_end() {
    var empty_below = voxels.indexWhere((layer) => layer.any((row) => row.any((v) => v != 0)));
    if (empty_below == -1) empty_below = 0;

    var empty_above = voxels.lastIndexWhere((layer) => layer.any((row) => row.any((v) => v != 0)));
    if (empty_above == -1) empty_above = voxels.length - 1;

    final it = voxels.skip(empty_below).take(empty_above - empty_below).toList(growable: false);
    return Voxels(width, it.length, depth, it, palette);
  }
}

Voxels read_vox(Uint8List riff, String name, {bool crop = true, int pad = 8}) {
  final header = (String.fromCharCodes(riff.getRange(0, 4)));
  if (header != 'VOX ') throw ArgumentError('Not a VOX file: $header');

  if (pad.isOdd || pad < 0) throw 'pad must be even and positive: $pad';

  late int width;
  late int height;
  late int depth;
  late List<List<List<int>>> voxels;
  late List<int> palette;

  late Uint8List size;
  late Uint8List xyzi;
  late Uint8List rgba;

  var offset = 8;
  while (offset != -1) {
    offset = _parse(riff, offset, (id, data) {
      final bytes = data.buffer.asByteData();
      if (id == 'SIZE') {
        size = data;

        width = bytes.getUint32(0, Endian.little) + pad;
        depth = bytes.getUint32(4, Endian.little) + pad;
        height = bytes.getUint32(8, Endian.little) + pad;
        voxels = List.generate(height, (y) => List.generate(depth, (z) => List.generate(width, (x) => 0)));

        if (dev) logInfo('Size: ${width - pad} x ${depth - pad} x ${height - pad}');
      } else if (id == 'XYZI') {
        xyzi = data;

        final count = bytes.getUint32(0, Endian.little);
        var offset = 4;
        for (var i = 0; i < count; i++) {
          final x = data[offset++] + pad ~/ 2;
          final z = data[offset++] + pad ~/ 2;
          final y = data[offset++] + pad ~/ 2;
          final color = data[offset++];
          voxels[y][z][x] = color;
        }
      } else if (id == 'RGBA') {
        rgba = data;

        final colors = data.length ~/ 4;
        palette = List<int>.generate(colors, (i) {
          final r = data[i * 4 + 0];
          final g = data[i * 4 + 1];
          final b = data[i * 4 + 2];
          final a = data[i * 4 + 3];
          return (a << 24) | (r << 16) | (g << 8) | b;
        });
        // } else if (id == 'MATL') {
        //   final ext = _VoxExt(data);
        //   final id = ext.nextInt();
        //   final dict_size = ext.nextInt();
        //   for (var i = 0; i < dict_size; i++) {
        //     final key = ext.nextString();
        //     final value = ext.nextString();
        //     // logInfo('Material: $id $key=$value');
        //   }
        // } else {
        //   logInfo('Unknown chunk: $id');
      }
    });
  }

  if (dev && !kIsWeb && !kIsWasm && name.endsWith('.vox')) {
    final out = File(name.replaceAll('.vox', '.vx')).openSync(mode: FileMode.writeOnly);
    out.writeStringSync('VOX ');
    out.writeFromSync(_little_unit32(0));
    _append(out, 'SIZE', size);
    _append(out, 'XYZI', xyzi);
    _append(out, 'RGBA', rgba);
    out.close();
  }

  final result = Voxels(width, height, depth, voxels, palette);
  return crop ? result.remove_empty_ys_at_start_and_end() : result;
}

void _append(RandomAccessFile out, String id, Uint8List data) {
  out.writeStringSync(id);
  out.writeFromSync(_little_unit32(data.lengthInBytes));
  out.writeFromSync(_little_unit32(0));
  out.writeFromSync(data);
}

Uint8List _little_unit32(int value) {
  final data = Uint8List(4);
  final bytes = data.buffer.asByteData();
  bytes.setUint32(0, value, Endian.little);
  return data;
}

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

int _parse(
  Uint8List riff,
  int offset,
  void Function(String, Uint8List) on_data,
) {
  if (offset == -1 || offset >= riff.length) return -1;

  final id = String.fromCharCodes(riff.getRange(offset, offset + 4));
  final size = riff.buffer.asByteData().getUint32(offset + 4, Endian.little);
  final children = riff.buffer.asByteData().getUint32(offset + 8, Endian.little);

  if (dev) logVerbose('Chunk: $id $size $children');

  on_data(id, riff.sublist(offset + 12, offset + 12 + size));
  offset += 12 + size;
  for (var i = 0; i < children; i++) {
    offset = _parse(riff, offset, on_data);
  }
  return offset;
}

class _VoxExt {
  final Uint8List data;
  int offset = 0;

  _VoxExt(this.data);

  int nextInt() {
    final value = data.buffer.asByteData().getUint32(offset, Endian.little);
    offset += 4;
    return value;
  }

  String nextString() {
    final length = nextInt();
    final value = String.fromCharCodes(data.sublist(offset, offset + length));
    offset += length;
    return value;
  }
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

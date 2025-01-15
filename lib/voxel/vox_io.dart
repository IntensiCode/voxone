import 'dart:typed_data';
import 'dart:ui';

import 'package:voxone/util/pixelate.dart';

class Voxels {
  final int width;
  final int height;
  final int depth;
  final List<List<List<int>>> voxels; // y layers, z- then x-planes
  final List<int> palette;

  Voxels(this.width, this.height, this.depth, this.voxels, this.palette);
}

Voxels read_vox(Uint8List riff) {
  final header = (String.fromCharCodes(riff.getRange(0, 4)));
  if (header != 'VOX ') throw ArgumentError('Not a VOX file: $header');

  late int width;
  late int height;
  late int depth;
  late List<List<List<int>>> voxels;
  late List<int> palette;

  var offset = 8;
  while (offset != -1) {
    offset = _parse(riff, offset, (id, data) {
      if (id == 'SIZE') {
        width = data.buffer.asByteData().getUint32(0, Endian.little) + 10;
        depth = data.buffer.asByteData().getUint32(4, Endian.little) + 10;
        height = data.buffer.asByteData().getUint32(8, Endian.little) + 10;
        voxels = List.generate(height, (y) => List.generate(depth, (z) => List.generate(width, (x) => 0)));
      } else if (id == 'XYZI') {
        final count = data.buffer.asByteData().getUint32(0, Endian.little);
        var offset = 4;
        for (var i = 0; i < count; i++) {
          final x = data[offset++];
          final z = data[offset++];
          final y = data[offset++];
          final color = data[offset++];
          voxels[y][z][x] = color;
        }
      } else if (id == 'RGBA') {
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
  return Voxels(width, height, depth, voxels, palette);
}

Image vox_to_image(Voxels voxels, [List<int>? blurred_argb32]) {
  final blurred = blurred_argb32 ??= [];
  return pixelate(voxels.width, voxels.height * voxels.depth, (canvas) {
    final paint = Paint()..style = PaintingStyle.fill;
    final blur = MaskFilter.blur(BlurStyle.outer, 1);
    for (var y = 0; y < voxels.height; y++) {
      for (var z = 0; z < voxels.depth; z++) {
        for (var x = 0; x < voxels.width; x++) {
          final v = voxels.voxels[voxels.height - 1 - y][voxels.depth - 1 - z][voxels.width - 1 - x];
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

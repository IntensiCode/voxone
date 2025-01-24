import 'dart:io';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flutter/foundation.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/voxel/voxels.dart';

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

// class _VoxExt {
//   final Uint8List data;
//   int offset = 0;
//
//   _VoxExt(this.data);
//
//   int nextInt() {
//     final value = data.buffer.asByteData().getUint32(offset, Endian.little);
//     offset += 4;
//     return value;
//   }
//
//   String nextString() {
//     final length = nextInt();
//     final value = String.fromCharCodes(data.sublist(offset, offset + length));
//     offset += length;
//     return value;
//   }
// }

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

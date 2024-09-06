import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../core/common.dart';

extension BitmapFontExtensions on BitmapFont {
  void tint(Color color) {
    paint.colorFilter = ColorFilter.mode(color, BlendMode.srcATop);
  }

  List<String> reflow(String text, int maxWidth, {double scale = 1}) {
    if (text.isEmpty) return [text]; // preserve paragraphs

    this.scale = scale;

    final lines = <String>[];
    final words = text.split(' ');
    var currentLine = StringBuffer();
    for (final word in words) {
      final check = '$currentLine $word';
      if (lineWidth(check) > maxWidth) {
        lines.add(currentLine.toString());
        currentLine.clear();
      }
      if (currentLine.isNotEmpty) currentLine.write(' ');
      currentLine.write(word);
    }
    if (currentLine.isNotEmpty) lines.add(currentLine.toString());
    return lines;
  }
}

abstract class BitmapFont {
  static loadMono(
    Images images,
    String filename, {
    required int charWidth,
    required int charHeight,
  }) async {
    final image = await images.load(filename);
    return MonospacedBitmapFont(image, charWidth, charHeight);
  }

  static loadDst(
    Images images,
    AssetsCache assets,
    String filename, {
    required int columns,
    required int rows,
  }) async {
    final image = await images.load(filename);
    final charWidth = image.width ~/ columns;
    final charHeight = image.height ~/ rows;

    late final Uint8List dst;
    try {
      dst = await _loadDst(assets, filename);
    } catch (e, trace) {
      logError('Failed to load bitmap font dst: $e', trace);
      dst = await _createDst(image, charWidth, charHeight, columns, rows);
    }
    return DstBitmapFont(image, dst, charWidth, charHeight);
  }

  static Future<Uint8List> _loadDst(AssetsCache assets, String filename) async {
    final hex = await assets.readFile(filename.replaceFirst('.png', '.dst'));
    final all = hex.split(RegExp(r'[\r\n ]+'));
    all.removeLast();
    final widths = all.map((it) => int.parse('0x$it'.trim()));
    return Uint8List.fromList(widths.toList());
  }

  static Future<Uint8List> _createDst(Image image, int charWidth, int charHeight, int columns, int rows) async {
    final pixels = await image.pixelsInUint8();
    final result = List.generate(columns * rows, (i) {
      if (i == 0) return charWidth ~/ 4;
      final x_off = (i % columns) * charWidth * 4;
      final y_off = (i ~/ columns) * charHeight * image.width * 4;
      var width = 0;
      for (int y = 0; y < charHeight; y++) {
        for (int x = charWidth - 1; x >= 0; x--) {
          final pixel = pixels[y_off + y * image.width * 4 + x_off + x * 4];
          if (pixel == 0) continue;
          width = max(width, x + 1);
          break;
        }
      }
      return width;
    });

    final dump = result.slices(columns).map((row) => (row.map((it) => it.toRadixString(16).padLeft(2, '0')).join(' ')));
    logInfo('\n${dump.join('\n')}\n');

    return Uint8List.fromList(result);
  }

  double scale = 1;
  double lineSpacing = 2;
  abstract double spacing;
  Paint paint = pixel_paint();

  Vector2 textSize(String text) {
    final lines = text.split('\n');
    final h = lineHeight(scale) * lines.length;
    final w = lines.map((it) => lineWidth(it)).max;
    return Vector2(w, h);
  }

  Sprite sprite(int charCode);

  double charWidth(int charCode, [double scale = 1]);

  double lineHeight([double scale = 1]);

  double lineWidth(String line);

  drawStringAligned(Canvas canvas, double x, double y, String text, Anchor anchor) {
    final w = lineWidth(text);
    final h = lineHeight();
    drawString(canvas, x - (w * anchor.x), y - (h * anchor.y), text);
  }

  drawString(Canvas canvas, double x, double y, String string);

  drawText(Canvas canvas, double x, double y, String text);
}

class MonospacedBitmapFont extends BitmapFont {
  final Image _image;
  final int _charWidth;
  final int _charHeight;
  final int _charsPerRow;

  @override
  late double spacing;

  MonospacedBitmapFont(this._image, this._charWidth, this._charHeight) : _charsPerRow = _image.width ~/ _charWidth {
    spacing = (_charWidth * 0.1).roundToDouble();
  }

  final _cache = <int, Rect>{};

  Rect _cachedSrc(int charCode) => _cache.putIfAbsent(charCode, () {
        final x = (charCode - 32) % _charsPerRow;
        final y = (charCode - 32) ~/ _charsPerRow;
        final rect = Rect.fromLTWH(
          x.toDouble() * _charWidth,
          y.toDouble() * _charHeight,
          _charWidth.toDouble(),
          _charHeight.toDouble(),
        );
        return rect;
      });

  Rect _dst(double x, double y) => Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        _charWidth.toDouble() * scale,
        _charHeight.toDouble() * scale,
      );

  @override
  Sprite sprite(int charCode) {
    final rect = _cachedSrc(charCode);
    return Sprite(_image, srcPosition: rect.topLeft.toVector2(), srcSize: rect.size.toVector2());
  }

  @override
  double charWidth(int charCode, [double scale = 1]) => _charWidth * scale;

  @override
  double lineHeight([double scale = 1]) => _charHeight * scale;

  @override
  double lineWidth(String line) => line.length * (_charWidth * scale + spacing * scale) - spacing * scale;

  @override
  drawString(Canvas canvas, double x, double y, String string) {
    for (final c in string.codeUnits) {
      final src = _cachedSrc(c);
      final dst = _dst(x, y);
      canvas.drawImageRect(_image, src, dst, paint);
      x += _charWidth * scale + spacing * scale;
    }
  }

  @override
  drawText(Canvas canvas, double x, double y, String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      drawString(canvas, x, y, line);
      y += _charHeight * scale + lineSpacing;
    }
  }
}

class DstBitmapFont extends BitmapFont {
  final Image _image;
  final Uint8List _dst;
  final int _charWidth;
  final int _charHeight;
  final int _charsPerRow;

  @override
  late double spacing;

  DstBitmapFont(this._image, this._dst, this._charWidth, this._charHeight) : _charsPerRow = _image.width ~/ _charWidth {
    spacing = (_charWidth * 0.1).roundToDouble();
  }

  final _cache = <int, Rect>{};

  Rect _cachedSrc(int charCode) => _cache.putIfAbsent(charCode, () {
        final x = (charCode - 32) % _charsPerRow;
        final y = (charCode - 32) ~/ _charsPerRow;
        var width = _dst[charCode - 32];
        if (width == 0) width = _charWidth ~/ 2;
        final rect = Rect.fromLTWH(
          x.toDouble() * _charWidth,
          y.toDouble() * _charHeight,
          width.toDouble(),
          _charHeight.toDouble(),
        );
        return rect;
      });

  Rect _dstRect(double x, double y, double width) => Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width * scale,
        _charHeight.toDouble() * scale,
      );

  @override
  Sprite sprite(int charCode) {
    final rect = _cachedSrc(charCode);
    return Sprite(_image, srcPosition: rect.topLeft.toVector2(), srcSize: rect.size.toVector2());
  }

  @override
  double charWidth(int charCode, [double scale = 1]) => _cachedSrc(charCode).width * scale;

  @override
  double lineHeight([double scale = 1]) => _charHeight * scale;

  @override
  double lineWidth(String line) {
    double x = 0;
    for (final c in line.codeUnits) {
      final src = charWidth(c, scale);
      x += src + spacing * scale;
    }
    return x - spacing * scale;
  }

  @override
  drawString(Canvas canvas, double x, double y, String string) {
    for (final c in string.codeUnits) {
      final src = _cachedSrc(c);
      final dst = _dstRect(x, y, src.width);
      canvas.drawImageRect(_image, src, dst, paint);
      x += src.width * scale + spacing * scale;
    }
  }

  @override
  drawText(Canvas canvas, double x, double y, String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      drawString(canvas, x, y, line);
      y += _charHeight * scale + lineSpacing;
    }
  }
}

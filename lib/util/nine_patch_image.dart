import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/util/mutable.dart';

class NinePatchComponent extends PositionComponent with HasPaint {
  final Sprite image;
  final int cornerSize;

  NinePatchComponent({
    required this.image,
    this.cornerSize = 8,
    Vector2? position,
    required Vector2 size,
    super.anchor,
  }) {
    if (position != null) this.position = position;
    this.size = size;

    if (width ~/ cornerSize * cornerSize != width) {
      throw ArgumentError('must be multiple of $cornerSize: $width');
    }
    if (height ~/ cornerSize * cornerSize != height) {
      throw ArgumentError('must be multiple of $cornerSize: $height');
    }
  }

  @override
  void onLoad() => ninePatchImage = NinePatchImage(image, cornerSize: cornerSize);

  late final NinePatchImage ninePatchImage;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    ninePatchImage.draw(canvas, 0, 0, width, height, paint);
  }
}

class NinePatchImage {
  final Sprite image;
  final int cornerSize;

  late final double _size = cornerSize.toDouble();

  NinePatchImage(this.image, {this.cornerSize = 8});

  Rect get _topLeft => Rect.fromLTWH(0, 0, _size, _size);

  Rect get _top => Rect.fromLTWH(_size, 0, _size, _size);

  Rect get _topRight => Rect.fromLTWH(_size * 2, 0, _size, _size);

  Rect get _left => Rect.fromLTWH(0, _size, _size, _size);

  Rect get _right => Rect.fromLTWH(_size * 2, _size, _size, _size);

  Rect get _center => Rect.fromLTWH(_size, _size, _size, _size);

  Rect get _bottomLeft => Rect.fromLTWH(0, _size * 2, _size, _size);

  Rect get _bottom => Rect.fromLTWH(_size, _size * 2, _size, _size);

  Rect get _bottomRight => Rect.fromLTWH(_size * 2, _size * 2, _size, _size);

  final paint = pixel_paint();

  draw(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height, [
    Paint? paint,
  ]) {
    if (width ~/ cornerSize * cornerSize != width) {
      throw ArgumentError('must be multiple of $cornerSize: $width');
    }
    if (height ~/ cornerSize * cornerSize != height) {
      throw ArgumentError('must be multiple of $cornerSize: $height');
    }

    final yTiles = height ~/ cornerSize;
    final xTiles = width ~/ cornerSize;
    final yLast = yTiles - 1;
    final xLast = xTiles - 1;

    for (var y = 0; y < yTiles; y++) {
      for (var x = 0; x < xTiles; x++) {
        final Rect src;
        if (x == 0 && y == 0) {
          src = _topLeft;
        } else if (x == xLast && y == 0) {
          src = _topRight;
        } else if (x == 0 && y == yLast) {
          src = _bottomLeft;
        } else if (x == xLast && y == yLast) {
          src = _bottomRight;
        } else if (y == 0) {
          src = _top;
        } else if (y == yLast) {
          src = _bottom;
        } else if (x == 0) {
          src = _left;
        } else if (x == xLast) {
          src = _right;
        } else {
          src = _center;
        }

        final yy = top + y * cornerSize;
        final xx = left + x * cornerSize;
        _dst.left = xx;
        _dst.top = yy;
        _dst.right = xx + _size;
        _dst.bottom = yy + _size;

        _src.copy(src);
        _src.add(image.srcPosition);
        canvas.drawImageRect(image.image, _src, _dst, paint ?? this.paint);
      }
    }
  }

  final _src = MutableRect.fromRect(Rect.zero);
  final _dst = MutableRect.fromRect(Rect.zero);
}

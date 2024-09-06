import 'dart:math';
import 'dart:ui';

class MutRect implements Rect {
  @override
  late double bottom;

  @override
  Offset get bottomCenter => Offset((left + right) / 2, bottom);

  @override
  Offset get bottomLeft => Offset(left, bottom);

  @override
  Offset get bottomRight => Offset(right, bottom);

  @override
  Offset get center => Offset((left + right) / 2, (bottom + top) / 2);

  @override
  Offset get centerLeft => Offset(left, (bottom + top) / 2);

  @override
  Offset get centerRight => Offset(right, (bottom + top) / 2);

  @override
  bool contains(Offset offset) {
    if (offset.dx < left) return false;
    if (offset.dx > right) return false;
    if (offset.dy < min(bottom, top)) return false;
    if (offset.dy > max(bottom, top)) return false;
    return true;
  }

  @override
  Rect deflate(double delta) {
    // TODO: implement deflate
    throw UnimplementedError();
  }

  @override
  Rect expandToInclude(Rect other) {
    // TODO: implement expandToInclude
    throw UnimplementedError();
  }

  @override
  bool get hasNaN => left.isNaN || right.isNaN || bottom.isNaN || top.isNaN;

  @override
  double get height => (top - bottom).abs();

  @override
  Rect inflate(double delta) {
    // TODO: implement inflate
    throw UnimplementedError();
  }

  @override
  Rect intersect(Rect other) {
    // TODO: implement intersect
    throw UnimplementedError();
  }

  @override
  bool get isEmpty => width == 0 || height == 0;

  @override
  bool get isFinite => !isEmpty && !hasNaN;

  @override
  bool get isInfinite => !isFinite;

  @override
  late double left;

  @override
  double get longestSide => max(width, height);

  @override
  bool overlaps(Rect other) {
    // TODO: implement overlaps
    throw UnimplementedError();
  }

  @override
  late double right;

  @override
  Rect shift(Offset offset) => translate(offset.dx, offset.dy);

  @override
  double get shortestSide => min(width, height);

  @override
  Size get size => Size(width, height);

  @override
  late double top;

  @override
  Offset get topCenter => Offset((left + right) / 2, top);

  @override
  Offset get topLeft => Offset(left, top);

  @override
  Offset get topRight => Offset(right, top);

  @override
  Rect translate(double translateX, double translateY) =>
      MutRect(left + translateX, top + translateY, right + translateX, bottom + translateY);

  @override
  double get width => (right - left).abs();

  MutRect.zero() : this(0, 0, 0, 0);

  MutRect(double l, double t, double r, double b)
      : left = l,
        top = t,
        right = r,
        bottom = b;
}

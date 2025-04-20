import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

// horrific... but seems to work... for now...

class MutableOffset extends Offset {
  MutableOffset(super.dx, super.dy);

  void setFrom(Vector2 other) {
    dx = other.x;
    dy = other.y;
  }

  @override
  double dx = 0;

  @override
  double dy = 0;
}

/// A mutable version of [Rect] for tile map animations.
@Deprecated('Use `MutRect` instead')
class MutableRect extends Rect {
  /// Construct a rectangle from its left, top, right, and bottom edges.
  MutableRect.fromLTRB(this.left, this.top, this.right, this.bottom)
      : super.fromLTRB(left, top, right, bottom);

  /// Create a new instance from [other].
  factory MutableRect.fromRect(Rect other) =>
      MutableRect.fromLTRB(other.left, other.top, other.right, other.bottom);

  /// The offset of the left edge of this rectangle from the x axis.
  @override
  double left;

  /// The offset of the top edge of this rectangle from the y axis.
  @override
  double top;

  /// The offset of the right edge of this rectangle from the x axis.
  @override
  double right;

  /// The offset of the bottom edge of this rectangle from the y axis.
  @override
  double bottom;

  void add(Vector2 xy) {
    left += xy.x;
    top += xy.y;
    right += xy.x;
    bottom += xy.y;
  }

  /// Update with [other]'s dimensions.
  void copy(Rect other) {
    left = other.left;
    top = other.top;
    right = other.right;
    bottom = other.bottom;
  }

  /// Convert to immutable rectangle.
  Rect toRect() => Rect.fromLTRB(left, top, right, bottom);
}

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
  Rect translate(double translateX, double translateY) => MutRect(
      left + translateX,
      top + translateY,
      right + translateX,
      bottom + translateY);

  @override
  double get width => (right - left).abs();

  MutRect.zero() : this(0, 0, 0, 0);

  MutRect(double l, double t, double r, double b)
      : left = l,
        top = t,
        right = r,
        bottom = b;
}

class MutablePair<A, B> {
  A first;
  B second;

  MutablePair(this.first, this.second);

  void setFrom(A a, B b) {
    first = a;
    second = b;
  }
}

import 'dart:math';

import 'package:flame/components.dart';

final rng = Random();

Vector2 randomNormalizedVector2() => Vector2(rng.nextDoublePM(1), rng.nextDoublePM(1))..normalize();

extension RandomExtensions on Random {
  double nextDoubleLimit(double limit) => nextDouble() * limit;

  double nextDoublePM(double limit) => (nextDouble() - nextDouble()) * limit;
}

extension Vector2Extensions on Vector2 {
  void randomizedNormal() {
    setValues(rng.nextDoublePM(1), rng.nextDoublePM(1));
    normalize();
  }
}

import 'dart:math';

import 'package:flame/components.dart';

final rng = Random();

Vector2 randomNormalizedVector2() => Vector2.random(rng) - Vector2.random(rng);

Vector3 randomNormalizedVector3() => Vector3.random(rng) - Vector3.random(rng);

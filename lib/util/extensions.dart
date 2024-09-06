import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/sprite.dart';
import 'package:kart/kart.dart';

extension ComponentExtension on Component {
  PositionComponent get ppc => parent! as PositionComponent;

  T added<T extends Component>(T it) {
    add(it);
    return it;
  }

  void fadeInDeep({double seconds = 0.2, bool restart = true}) {
    if (this case OpacityProvider it) {
      if (it.opacity == 1 && !restart) return;
      if (it.opacity > 0 && restart) it.opacity = 0;
      add(OpacityEffect.to(1, EffectController(duration: seconds)));
    }
    for (final it in children) {
      it.fadeInDeep(seconds: seconds, restart: restart);
    }
  }

  void fadeOutDeep({double seconds = 0.2, bool restart = false, bool and_remove = true}) {
    if (this case OpacityProvider it) {
      if (it.opacity == 0 && !restart) return;
      if (it.opacity < 1 && restart) it.opacity = 1;
      add(OpacityEffect.to(0, EffectController(duration: seconds)));
    }
    for (final it in children) {
      it.fadeOutDeep(seconds: seconds, restart: restart, and_remove: false);
    }
    if (and_remove) add(RemoveEffect(delay: seconds));
  }

  void runScript(List<(int, void Function())> script) {
    for (final step in script) {
      _doAt(step.$1, () {
        if (!isMounted) return;
        step.$2();
      });
    }
  }

  void _doAt(int millis, Function() what) {
    Future.delayed(Duration(milliseconds: millis)).then((_) => what());
  }
}

extension ComponentSetExtensions on ComponentSet {
  operator -(Component component) => where((it) => it != component);
}

extension DynamicListExtensions on List<dynamic> {
  List<T> mapToType<T>() => map((it) => it as T).toList();

  void rotateLeft() => add(removeAt(0));

  void rotateRight() => insert(0, removeLast());
}

extension IterableExtensions<T> on Iterable<T> {
  List<R> mapList<R>(R Function(T) f) => map(f).toList();

  Iterable<T> operator +(Iterable<T> other) sync* {
    for (final e in this) {
      yield e;
    }
    for (final o in other) {
      yield o;
    }
  }
}

extension ListExtensions<T> on List<T> {
  void fill(T it) => fillRange(0, length, it);

  List<R> mapList<R>(R Function(T) f) => map(f).toList();

  T? nextAfter(T? it) {
    if (it == null) return firstOrNull();
    final index = indexOf(it);
    if (index == -1) return null;
    return this[(index + 1) % length];
  }

  void removeAll(Iterable<T> other) {
    for (final it in other) {
      remove(it);
    }
  }

  T? removeLastOrNull() {
    if (isEmpty) return null;
    return removeLast();
  }

  List<T> operator -(List<T> other) => whereNot((it) => other.contains(it)).toList();
}

extension RandomExtensions on Random {
  double nextDoubleLimit(double limit) => nextDouble() * limit;

  double nextDoublePM(double limit) => (nextDouble() - nextDouble()) * limit;
}

extension FragmentShaderExtensions on FragmentShader {
  setVec4(int index, Color color) {
    final r = color.red / 255 * color.opacity;
    final g = color.green / 255 * color.opacity;
    final b = color.blue / 255 * color.opacity;
    setFloat(index + 0, r);
    setFloat(index + 1, g);
    setFloat(index + 2, b);
    setFloat(index + 3, color.opacity);
  }
}

extension IntExtensions on int {
  forEach(void Function(int) f) {
    for (var i = 0; i < this; i++) {
      f(i);
    }
  }
}

extension PaintExtensions on Paint {
  double get opacity => color.opacity;

  set opacity(double progress) {
    color = Color.fromARGB((255 * progress).toInt(), 255, 255, 255);
  }
}

extension StringExtensions on String {
  List<String> lines() => split('\n');
}

extension Vector2Extensions on Vector2 {
  RSTransform get transform => RSTransform.fromComponents(
        rotation: 0,
        scale: 1.0,
        anchorX: 0,
        anchorY: 0,
        translateX: x,
        translateY: y,
      );
}

extension Vector3Extension on Vector3 {
  void lerp(Vector3 other, double t) {
    x = x + (other.x - x) * t;
    y = y + (other.y - y) * t;
    z = z + (other.z - z) * t;
  }
}

extension SpriteSheetExtensions on SpriteSheet {
  Sprite by_row(int row, double progress) => getSprite(row, ((columns - 1) * progress).toInt());

  Sprite by_progress(double progress) => getSpriteById(((columns - 1) * progress).toInt());
}

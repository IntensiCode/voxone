import 'package:flame/components.dart';

mixin Recyclable on Component {
  late Function() recycle;
}

class ComponentRecycler<T extends Recyclable> {
  ComponentRecycler(this._create);

  final T Function() _create;

  final _pool = <T>[];

  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeLast();
    } else {
      final it = _create();
      it.recycle = () => recycle(it);
      return it;
    }
  }

  void recycle(T component) {
    component.removeFromParent();
    _pool.add(component);
  }
}

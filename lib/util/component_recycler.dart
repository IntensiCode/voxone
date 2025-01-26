import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';

mixin Recyclable on Component {
  bool recycled = false;
  late Function() recycle;
}

class ComponentRecycler<T extends Recyclable> {
  ComponentRecycler(this._create);

  final T Function() _create;

  final items = <T>[];

  T acquire() {
    if (items.isNotEmpty) {
      return items.removeLast()..recycled = false;
    } else {
      final it = _create();
      it.recycle = () => recycle(it);
      return it;
    }
  }

  void recycle(T component) {
    // if (component.recycled && dev) {
    //   if (component.isMounted && !component.isRemoving) throw 'no no';
    //   if (!_pool.contains(component)) throw 'oh no no';
    //   if (_pool.contains(component)) logError('ignore duplicate recycle: $component', StackTrace.current);
    // }

    if (component.isMounted) component.removeFromParent();
    if (!component.recycled && !items.contains(component)) items.add(component);
    component.recycled = true;
  }
}

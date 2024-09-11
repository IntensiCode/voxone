import 'package:supercharged/supercharged.dart';

mixin Particle {
  bool active = false;
}

class ParticleRecycler<T extends Particle> {
  ParticleRecycler(this._create);

  final T Function() _create;

  final _pool = <T>[];

  Iterable<T> get active => _pool.filter((it) => it.active);

  T acquire() => _acquire()..active = true;

  T _acquire() {
    final inactive = _pool.filter((it) => !it.active).firstOrNull;
    if (inactive != null) return inactive;

    final it = _create();
    _pool.add(it);
    return it;
  }
}

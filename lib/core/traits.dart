extension ObjectExtensions on Object {
  bool hasTrait<T>() => traits<T>().isNotEmpty;

  T firstTrait<T>() => traits<T>().first;

  T singleTrait<T>() => traits<T>().single;

  /// Get all traits of type [T] from this object and all its traits. Using depth-first search.
  Iterable<T> traits<T>() sync* {
    if (this is HasTraits) {
      yield* (this as HasTraits).traits<T>();
    } else if (this is T) {
      yield this as T;
    }
  }

  /// Convenience method to check if **any** trait of type [T] fulfills [check], and if so, call [func] on **all**
  /// traits of type [T]. **Note any vs all**.
  void ifTraits<T>(bool Function(T) check, void Function(T) func) {
    if (this is HasTraits) {
      (this as HasTraits).traits<T>().where(check).forEach(func);
    } else if (this is T && check(this as T)) {
      func(this as T);
    }
  }

  /// Call [func] on **all** traits of type [T].
  void onTraits<T>(void Function(T) func) {
    if (this is HasTraits) {
      (this as HasTraits).onTraits(func);
    } else if (this is T) {
      func(this as T);
    }
  }
}

mixin HasTraits {
  final _traits = <dynamic>[];

  void addTrait(dynamic trait) => _traits.add(trait);

  T firstTrait<T>() => traits<T>().first;

  T singleTrait<T>() => traits<T>().single;

  bool hasTrait<T>() => traits<T>().isNotEmpty;

  /// Get all traits of type [T] from this object and all its traits. Using depth-first search.
  Iterable<T> traits<T>() sync* {
    if (this is T) yield this as T;
    yield* _traits.expand((it) => it is HasTraits
        ? it.traits<T>()
        : it is T
            ? [it]
            : []);
  }

  /// Convenience method to check if **any** trait of type [T] fulfills [check], and if so, call [func] on **all**
  /// traits of type [T]. **Note any vs all**.
  void ifTraits<T>(bool Function(T) check, void Function(T) func) => traits<T>().where(check).forEach(func);

  /// Call [func] on **all** traits of type [T].
  void onTraits<T>(void Function(T) func) => traits<T>().forEach(func);
}

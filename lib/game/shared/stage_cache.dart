import 'package:flame/components.dart';
import 'package:stardash/util/auto_dispose.dart';

/// Components go in here after being looked up once in the component hierarchy. The cache is 'per stage'. Because
/// every stage will have a different player, etc, ofc. Be careful to put only components in here with a lifetime
/// equal to the entire stage. That is what this is cache is meant for **only**.
///
/// In addition, if something inside the cache needs to be explicitly disposed, make sure to call [addDisposable]
/// with it, unless it **is** a [Disposable] itself. Why this indirection? Because something could contain one or
/// more [Image]s. It itself cannot always implement [Disposable]. Therefore, you need to add everything that has to
/// be disposed explicitly to the cache.
class StageCache extends Component implements Disposable {
  final _cache = <String, Object>{};
  final _disposables = <Disposable>{};

  bool has(String key) => _cache.containsKey(key);

  operator [](String key) => _cache[key];

  operator []=(String key, Object value) => _cache[key] = value;

  T require<T>(String key) => _cache[key] as T;

  T putIfAbsent<T>(String key, T Function() ifAbsent) {
    if (!_cache.containsKey(key)) {
      final it = ifAbsent();
      _cache[key] = it as Object;
      if (it is Disposable) addDisposable(it);
    }
    return _cache[key] as T;
  }

  /// See the discussion in the class doc: [StageCache].
  void addDisposable(Disposable disposable) => _disposables.add(disposable);

  @override
  void dispose() {
    _cache.clear();
    for (final it in _disposables) {
      it.dispose();
    }
  }
}

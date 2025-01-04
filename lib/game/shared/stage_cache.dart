import 'package:flame/components.dart';

/// Components go in here after being looked up once in the component hierarchy. The cache is 'per stage'. Because
/// every stage will have a different player, etc, ofc. Be careful to put only components in here with a lifetime
/// equal to the entire stage. That is what this is cache is meant for **only**.
class StageCache extends Component {
  final _cache = <String, Object>{};

  operator [](String key) => _cache[key];

  T putIfAbsent<T>(String key, T Function() ifAbsent) {
    if (!_cache.containsKey(key)) {
      _cache[key] = ifAbsent() as Object;
    }
    return _cache[key] as T;
  }
}

import 'dart:ui';

class Uniforms<T> {
  Uniforms(this.shader, Iterable<T> all) {
    all.forEach(define);
  }

  final FragmentShader shader;

  final _ids = <T, int>{};

  void define(T id) => _ids[id] = _ids.length;

  void set(T id, double value) => shader.setFloat(_ids[id]!, value);

  operator []=(T id, double value) => shader.setFloat(_ids[id]!, value);
}

import 'dart:ui';

Future<FragmentShader> loadShader(String name) async =>
    (await FragmentProgram.fromAsset('assets/shaders/$name')).fragmentShader();

class Uniforms<T> {
  Uniforms(this.shader, Iterable<T> all) {
    for (final it in all) {
      define(it);
    }
  }

  final FragmentShader shader;

  final _ids = <T, int>{};

  void define(T id) => _ids[id] = _ids.length;

  void set(T id, double value) => shader.setFloat(_ids[id]!, value);

  operator []=(T id, double value) => shader.setFloat(_ids[id]!, value);
}

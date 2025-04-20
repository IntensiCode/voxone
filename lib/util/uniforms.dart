import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

Future<FragmentShader> loadShader(String name) async =>
    (await FragmentProgram.fromAsset('assets/shaders/$name')).fragmentShader();

class Uniforms<T> {
  Uniforms(this.shader, Iterable<T> all) {
    for (final it in all) {
      define(it);
    }
  }

  void switch_shader(FragmentShader it) {
    shader = it;
  }

  FragmentShader shader;

  final _ids = <T, int>{};

  void define(T id) => _ids[id] = _ids.length;

  void set(T id, double value) => shader.setFloat(_ids[id]!, value);

  operator []=(T id, double value) => shader.setFloat(_ids[id]!, value);
}

class UniformsExt<T extends Enum> {
  UniformsExt(this.shader, Map<T, Type> definitions) {
    int currentIndex = 0;
    for (final entry in definitions.entries) {
      final id = entry.key;
      final type = entry.value;
      int size;
      Object? Function(dynamic value) setter;

      if (type == double) {
        size = 1;
        setter = (dynamic value) {
           assert(value is double, "Uniform $id requires a double, got ${value.runtimeType}");
           return shader.setFloat(_uniformLocations[id]![0], value as double);
        };
      } else if (type == Vector2) {
         size = 2;
         setter = (dynamic value) {
            assert(value is Vector2, "Uniform $id requires a Vector2, got ${value.runtimeType}");
            final vec = value as Vector2;
            final loc = _uniformLocations[id]!;
            shader.setFloat(loc[0], vec.x);
            shader.setFloat(loc[1], vec.y);
            return null;
         };
      } else if (type == Vector3) {
        size = 3;
        setter = (dynamic value) {
            assert(value is Vector3, "Uniform $id requires a Vector3, got ${value.runtimeType}");
            final vec = value as Vector3;
            final loc = _uniformLocations[id]!;
            shader.setFloat(loc[0], vec.x);
            shader.setFloat(loc[1], vec.y);
            shader.setFloat(loc[2], vec.z);
            return null;
        };
      } else if (type == Vector4) {
         size = 4;
         setter = (dynamic value) {
            assert(value is Vector4, "Uniform $id requires a Vector4, got ${value.runtimeType}");
            final vec = value as Vector4;
            final loc = _uniformLocations[id]!;
            shader.setFloat(loc[0], vec.x);
            shader.setFloat(loc[1], vec.y);
            shader.setFloat(loc[2], vec.z);
            shader.setFloat(loc[3], vec.w);
            return null;
         };
      } else if (type == Matrix4) {
          size = 16;
          setter = (dynamic value) {
              assert(value is Matrix4, "Uniform $id requires a Matrix4, got ${value.runtimeType}");
              final mat = value as Matrix4;
              final loc = _uniformLocations[id]!;
              final storage = mat.storage;
              for (int i=0; i<16; ++i) {
                  shader.setFloat(loc[i], storage[i]);
              }
              return null;
          };
      } else {
        assert(false, "Unsupported uniform type: $type for $id");
        size = 0;
        setter = (dynamic value) { assert(false, "Cannot set value for unsupported type $type"); return null; };
      }

      _uniformLocations[id] = List.generate(size, (i) => currentIndex + i);
      _setters[id] = setter;
      currentIndex += size;
    }
  }

  FragmentShader shader;
  final _uniformLocations = <T, List<int>>{};
  final _setters = <T, Object? Function(dynamic value)>{};

  void set(T id, dynamic value) {
    final setter = _setters[id];
    assert(setter != null, "Uniform $id not defined.");
    setter!(value);
  }

  operator []=(T id, dynamic value) => set(id, value);

  void switch_shader(FragmentShader it) {
    shader = it;
  }
}

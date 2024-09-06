import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/util/uniforms.dart';

enum Uniform {
  scr_x,
  scr_y,
  scr_width,
  scr_height,
  image_width,
  image_height,
}

class Ground extends Component {
  final _rng = Random(0);

  final _hole = pixel_paint()
    ..blendMode = BlendMode.multiply
    ..color = const Color(0xF0e0d0b0);

  final _rect = const Rect.fromLTWH(0, 0, game_width, game_height);
  final _pixel_paint = pixel_paint();

  late final _width = game_width * 4;
  late final _height = game_height * 4;

  late final Image _ground;
  late final FragmentShader _shader;
  late final Uniforms _uniforms;
  late final Paint _paint;

  double _time = 0;
  final _pos = Vector2(160, 120);

  @override
  Future<void> onLoad() async {
    final recorder = PictureRecorder();

    final noise = pixel_paint();
    final noise_program = await FragmentProgram.fromAsset('assets/shaders/noise.frag');
    final shader = noise_program.fragmentShader();
    shader.setFloat(0, _width);
    shader.setFloat(1, _height);
    noise.shader = shader;
    final c = Canvas(recorder);
    // c.drawColor(const Color(0xFFa08040), BlendMode.srcOver);
    c.drawRect(Rect.fromLTWH(0, 0, _width, _height), noise);

    final picture = recorder.endRecording();
    _ground = picture.toImageSync(_width.toInt(), _height.toInt());
    picture.dispose();

    final ground_program = await FragmentProgram.fromAsset('assets/shaders/ground.frag');
    _shader = ground_program.fragmentShader();
    _shader.setImageSampler(0, _ground);

    _uniforms = Uniforms(_shader, Uniform.values);
    _uniforms.set(Uniform.scr_width, game_width);
    _uniforms.set(Uniform.scr_height, game_height);
    _uniforms.set(Uniform.image_width, _width);
    _uniforms.set(Uniform.image_height, _height);

    _paint = pixel_paint();
    _paint.shader = _shader;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _pos.x = 0 + _time * 100;
    _pos.y = 0 + _time * 100;
    _uniforms.set(Uniform.scr_x, _pos.x);
    _uniforms.set(Uniform.scr_y, _pos.y);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(_rect, _paint);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(game_width.toInt(), game_height.toInt());
    canvas.drawImage(image, Offset.zero, _pixel_paint);
    image.dispose();
    picture.dispose();
  }
}

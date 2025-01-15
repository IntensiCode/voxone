import 'dart:ui';

Image pixelate(int width, int height, void Function(Canvas) draw) {
  final recorder = PictureRecorder();
  draw(Canvas(recorder));
  final picture = recorder.endRecording();
  final result = picture.toImageSync(width, height);
  picture.dispose();
  return result;
}

import 'package:flame/events.dart';

mixin MouseWheelScrolling on DragCallbacks {
  double get drag_step;

  double _drag = 0;

  void onDragSteps(int steps);

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _drag += event.canvasDelta.y;
    final scroll = _drag ~/ drag_step;
    if (scroll == 0) return;
    _drag -= scroll * drag_step;
    onDragSteps(scroll);
  }
}

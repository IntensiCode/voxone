import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:voxone/game/stage1/marauder.dart';
import 'package:voxone/game/stage1/sweeping_marauder.dart';

class WarpingMarauder extends SweepingMarauder {
  @override
  void on_incoming(double dt) {
    incoming_time += dt * 2 / 3;
    if (incoming_time >= 1) {
      incoming_time = 1;
      state = MarauderState.active;
      entity.sprite.paint.imageFilter = null;
      entity.sprite.paint.colorFilter = null;
    }
    scale.setAll(0.2);
    scale.x += 4 - incoming_time * 4;
    priority = (scale.x * 1000).toInt();

    final i = Curves.easeInOut.transform(incoming_time);
    position.setFrom(target_position);
    position.x += 550;
    position.x -= 550 * i;

    entity.sprite.opacity = incoming_time;

    entity.sprite.paint.imageFilter = ImageFilter.blur(sigmaX: 32 * (1 - i), sigmaY: 32 * (1 - i));
    entity.sprite.paint.colorFilter = ColorFilter.mode(Colors.white, BlendMode.modulate);
  }
}

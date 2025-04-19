import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:stardash/aural/audio_system.dart';
import 'package:stardash/core/common.dart';
import 'package:stardash/game/shared/extra_id.dart';
import 'package:stardash/game/shared/extras.dart';
import 'package:stardash/game/shared/has_context.dart';
import 'package:stardash/game/shared/traits.dart';
import 'package:stardash/util/component_recycler.dart';
import 'package:stardash/util/extensions.dart';

class SmartBomb extends Component with HasContext, SecondaryWeapon {
  SmartBomb(Function(SecondaryWeapon) on_fired) {
    super.on_fired = on_fired;
    cooldown_time = 10;
  }

  late final _nukes = ComponentRecycler(() => _DestroyEverything(stage));

  @override
  String get display_name => 'Smart Bomb';

  @override
  Sprite get icon => extras.icon_for(ExtraId.smart_bomb);

  @override
  void do_fire() {
    stage.add(_nukes.acquire()..reset());
    audio.play(Sound.plasma, volume_factor: 0.5);
  }
}

class _DestroyEverything extends Component with Recyclable, HasPaint {
  _DestroyEverything(this.stage) {
    paint.color = white;
    priority = 5000;
  }

  final Component stage;

  double _life_time = 0;
  bool _applied = false;

  void reset() {
    _life_time = 0;
    _applied = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life_time += dt;
    if (_life_time > 1) recycle();
    if (_life_time > 0.5 && !_applied) {
      _applied = true;
      stage.children.whereType<Hostile>().whereType<Target>().forEach((it) => it.on_hit(damage: 100));
    }
  }

  @override
  void render(Canvas canvas) {
    final saved = paint.opacity;
    final x = _life_time < 0.5 ? _life_time * 2 : 1 - (_life_time - 0.5) * 2;
    final o = Curves.easeInOutCubic.transform(x.clamp(0, 1));
    paint.opacity *= o;
    canvas.drawRect(_rect, paint);
    paint.opacity = saved;
  }

  late final _rect = Rect.fromLTWH(0, 0, game_width, game_height);
}

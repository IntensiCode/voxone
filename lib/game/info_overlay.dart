import 'package:flame/components.dart';
import 'package:voxone/core/common.dart';
import 'package:voxone/game/messages.dart';
import 'package:voxone/util/effects.dart';
import 'package:voxone/util/extensions.dart';
import 'package:voxone/util/game_script.dart';
import 'package:voxone/util/on_message.dart';

class InfoOverlay extends GameScriptComponent {
  @override
  void onMount() {
    super.onMount();
    onMessage<ShowInfoText>((it) {
      clearScript();
      removeAll(children);

      late Component text;
      at(0.0, () {
        final t = it.title;
        if (t != null) textXY(t, game_width / 2, game_height / 2 - 15, scale: 2).fadeInDeep();
        text = textXY(it.text, game_width / 2, game_height / 2 + 5);
        text.fadeInDeep();
      });
      at(0.4, () {
        if (it.blink_text) text.add(BlinkEffect(on: 0.35, off: 0.15));
      });
      at(1.8, () => text.removeAll(text.children));
      at(1.0, () => fadeOutDeep());
      at(0.5, () => it.when_done?.call());
      executeScript();
    });
  }
}

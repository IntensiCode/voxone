import 'dart:async';

import 'auto_dispose.dart';
import 'game_script_functions.dart';

class GameScriptComponent extends AutoDisposeComponent with GameScriptFunctions, GameScript {}

mixin GameScript on GameScriptFunctions {
  var script = <Future Function()>[];

  StreamSubscription? active;

  void clearScript() {
    active?.cancel();
    active = null;
    script = [];
  }

  void at(double deltaSeconds, Function() execute) {
    script.add(() async {
      final millis = (deltaSeconds * 1000).toInt();
      await Future.delayed(Duration(milliseconds: millis)).then((_) async {
        if (!isMounted) return;
        return await execute();
      });
    });
  }

  loopAt(double deltaSeconds, Function() body) {
    at(deltaSeconds, () async {
      while (isMounted) {
        clearScript();
        body();
        await executeScript().asFuture();
      }
    });
  }

  StreamSubscription executeScript() {
    final it = Stream.fromIterable(script).asyncMap((it) async {
      if (!isMounted) return;
      return await it();
    });
    active = it.listen((it) {});
    return active!;
  }

  @override
  void onMount() {
    super.onMount();
    executeScript();
  }

  @override
  void onRemove() {
    super.onRemove();
    active?.cancel();
    active = null;
  }
}

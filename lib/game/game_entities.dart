import 'dart:async';

import 'package:voxone/game/entities/prisoners.dart';
import 'package:voxone/game/game_context.dart';
import 'package:voxone/game/level/level_object.dart';
import 'package:voxone/game/level/level_tiles.dart';
import 'package:voxone/game/level/props/level_prop.dart';
import 'package:voxone/game/level/props/level_prop_extensions.dart';
import 'package:flame/components.dart';

class GameEntities extends Component {
  GameEntities() {
    entities = this;
  }

  final solids = <StackedTile>[];
  final consumables = <LevelProp>[];
  final destructibles = <LevelProp>[];
  final explosives = <LevelProp>[];
  final flammables = <LevelProp>[];
  final prisoners = <Prisoner>[];
  final enemies = <LevelObject>[];

  Iterable<LevelObject> get obstacles sync* {
    yield* solids;
    yield* destructibles;
  }

  @override
  FutureOr<void> add(Component component) {
    if (component is StackedTile) {
      _manage(component, solids);
    }
    if (component is LevelProp) {
      if (component.is_consumable) _manage(component, consumables);
      if (component.is_destructible) _manage(component, destructibles);
      if (component.is_explosive) _manage(component, explosives);
      if (component.is_flammable) _manage(component, flammables);
      if (component.is_enemy) _manage(component, enemies);
    }
    if (component is Prisoner) {
      _manage(component, prisoners);
    }
    return super.add(component);
  }

  void _manage<T extends Component>(T prop, List<T> list) {
    if (prop.isMounted) {
      list.add(prop);
    } else {
      prop.mounted.then((_) => list.add(prop));
    }
    prop.removed.then((_) => list.remove(prop));
  }
}
